#!/usr/bin/env bash
# deps.sh — install the packages the configs expect on Arch or Debian/Ubuntu.
#
# Arch-family systems use packages/arch.txt (pacman). Debian-family systems
# use apt for stable basics and Homebrew for the tools whose distro versions
# are too old (neovim, fzf, asciinema, tmux, ...) or that are not packaged.
#
#   scripts/deps.sh             install for this machine
#   scripts/deps.sh --dry-run   print what would be installed

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"
BREW=''
BREW_TOOLS='neovim fzf asciinema lazygit yazi lsd tmux bat btop fd fish jq ripgrep zoxide'

# Prefer our own links for now; brew is prepended once it is located.
PATH="$BIN_DIR:$PATH"
export PATH

MODE="${DEPS_MODE:-desktop}"
dry=0
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) dry=1 ;;
    -h|--help)
      printf 'usage: %s [--dry-run]\n' "${0##*/}"
      printf '  DEPS_MODE=server  install only what a server needs (no ghostty/opencode)\n' >&2
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$arg" >&2
      printf 'usage: %s [--dry-run]\n' "${0##*/}" >&2
      exit 2
      ;;
  esac
done

say()  { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }

run_root() {
  if [ "$dry" -eq 1 ]; then
    printf 'would run:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    warn 'need root or sudo to install packages'
    return 1
  fi
}

read_pkgs() {
  sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

install_arch() {
  local list="$ROOT/packages/arch.txt" pkgs=()
  [ -r "$list" ] || {
    warn "missing package list: $list"
    return 1
  }

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case "$MODE" in
      server) case "$p" in ghostty|opencode) continue ;; esac ;;
    esac
    pkgs+=("$p")
  done < <(read_pkgs "$list")
  [ "${#pkgs[@]}" -gt 0 ] || return 0

  say "Arch packages (${MODE}): ${pkgs[*]}"
  run_root pacman -S --needed "${pkgs[@]}"
}

install_debian() {
  local list="$ROOT/packages/debian.txt" wanted=() pkgs=() pkg
  [ -r "$list" ] || {
    warn "missing package list: $list"
    return 1
  }

  mapfile -t wanted < <(read_pkgs "$list")
  [ "${#wanted[@]}" -gt 0 ] || return 0

  say 'Updating apt package lists...'
  run_root env DEBIAN_FRONTEND=noninteractive apt-get update || return 1

  for pkg in "${wanted[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      pkgs+=("$pkg")
    else
      warn "skipping unavailable package: $pkg"
    fi
  done
  [ "${#pkgs[@]}" -gt 0 ] || return 0

  say "Debian packages: ${pkgs[*]}"
  run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
}

install_brew_tools() {
  local tool outdated_list upgrades=() brew_tools="$BREW_TOOLS"

  if [ "$dry" -eq 1 ]; then
    say "would run: brew install $brew_tools"
    return 0
  fi
  [ -n "$BREW" ] || {
    warn 'brew is not available'
    return 1
  }

  # shellcheck disable=SC2086 # word splitting is intended
  "$BREW" install $brew_tools || return 1

  outdated_list=$("$BREW" outdated --quiet --formula 2>/dev/null || true)
  for tool in $brew_tools; do
    if printf '%s\n' "$outdated_list" | grep -qx "$tool"; then
      upgrades+=("$tool")
    fi
  done

  if [ "${#upgrades[@]}" -gt 0 ]; then
    say "Upgrading: ${upgrades[*]}"
    "$BREW" upgrade "${upgrades[@]}" || return 1
  fi
}

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  local path
  for path in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$path" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  return 1
}

install_homebrew() {
  local brew
  if brew=$(find_brew); then
    BREW=$brew
  else
    if [ "$dry" -eq 1 ]; then
      say 'would install Homebrew (official installer, uses sudo)'
      return 0
    fi

    say 'Installing Homebrew...'
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1

    brew=$(find_brew) || {
      warn 'brew not found after installing Homebrew'
      return 1
    }
    BREW=$brew
  fi

  eval "$("$BREW" shellenv)"
  PATH="$BIN_DIR:$PATH"
  export PATH

  say "Homebrew: $("$BREW" --version | head -1)"
}

# Debian installs fd as fdfind and bat as batcat. Link the names the configs
# (and doctor) expect into ~/.local/bin.
link_compat() {
  local src=$1 dst=$2 target
  command -v "$dst" >/dev/null 2>&1 && return 0
  target=$(command -v "$src" 2>/dev/null) || return 0

  if [ "$dry" -eq 1 ]; then
    say "would link $BIN_DIR/$dst -> $target"
    return 0
  fi

  mkdir -p "$BIN_DIR"
  ln -sf "$target" "$BIN_DIR/$dst"
  say "Linked $BIN_DIR/$dst -> $target"
}

print_extra() {
  local file="$ROOT/packages/extra.txt" cmd hint missing=0

  # On Debian the brew formulas above handle these; only list what is still
  # missing after a real run.
  if [ "$dry" -eq 1 ] && [ "${family:-}" = debian ]; then
    return 0
  fi
  [ -r "$file" ] || return 0

  while IFS='|' read -r cmd hint; do
    case "$cmd" in ''|'#'*) continue ;; esac
    cmd=$(printf '%s' "$cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    hint=$(printf '%s' "$hint" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -n "$cmd" ] || continue
    command -v "$cmd" >/dev/null 2>&1 && continue

    if [ "$missing" -eq 0 ]; then
      printf '\nInstall these manually:\n'
      missing=1
    fi
    printf '  %-10s %s\n' "$cmd" "$hint"
  done <"$file"

  [ "$missing" -eq 0 ] || printf '\nThen run: make doctor\n'
}

family="${DEPS_FAMILY:-}"
if [ -z "$family" ]; then
  ids=''
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    ids=" ${ID:-} ${ID_LIKE:-} "
  fi

  case "$ids" in
    *" arch "*|*" cachyos "*) family=arch ;;
    *" debian "*|*" ubuntu "*) family=debian ;;
    *)
      if command -v pacman >/dev/null 2>&1; then
        family=arch
      elif command -v apt-get >/dev/null 2>&1; then
        family=debian
      fi
      ;;
  esac
fi

case "$family" in
  arch)
    install_arch || exit 1
    ;;
  debian)
    install_debian || exit 1
    install_homebrew || exit 1
    install_brew_tools || exit 1
    ;;
  *)
    warn 'unsupported distribution; install from packages/arch.txt (pacman) or packages/debian.txt (apt)'
    print_extra
    exit 1
    ;;
esac

print_extra
