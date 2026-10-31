#!/usr/bin/env bash
# deps.sh — install the packages the configs expect on Arch or Debian/Ubuntu.
#
# Arch-family systems use packages/arch.txt (pacman). Debian-family systems
# use packages/debian.txt (apt). Tools that are too old in distro archives, or
# not packaged at all, are listed in packages/extra.txt and printed when
# missing because they need an upstream install.
#
#   scripts/deps.sh             install for this machine
#   scripts/deps.sh --dry-run   print what would be installed

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

dry=0
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) dry=1 ;;
    -h|--help)
      printf 'usage: %s [--dry-run]\n' "${0##*/}"
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$arg" >&2
      printf 'usage: %s [--dry-run]\n' "${0##*/}" >&2
      exit 2
      ;;
  esac
done

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
    printf 'need root or sudo to install packages\n' >&2
    return 1
  fi
}

read_pkgs() {
  sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

install_arch() {
  local list="$ROOT/packages/arch.txt"
  [ -r "$list" ] || {
    printf 'missing package list: %s\n' "$list" >&2
    return 1
  }

  local pkgs=()
  mapfile -t pkgs < <(read_pkgs "$list")
  [ "${#pkgs[@]}" -gt 0 ] || return 0

  printf 'Arch packages: %s\n' "${pkgs[*]}"
  run_root pacman -S --needed "${pkgs[@]}"
}

install_debian() {
  local list="$ROOT/packages/debian.txt"
  [ -r "$list" ] || {
    printf 'missing package list: %s\n' "$list" >&2
    return 1
  }

  local wanted=() pkgs=() pkg
  mapfile -t wanted < <(read_pkgs "$list")
  [ "${#wanted[@]}" -gt 0 ] || return 0

  printf 'Updating apt package lists...\n'
  run_root env DEBIAN_FRONTEND=noninteractive apt-get update || return 1

  for pkg in "${wanted[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      pkgs+=("$pkg")
    else
      printf 'skipping unavailable package: %s\n' "$pkg" >&2
    fi
  done
  [ "${#pkgs[@]}" -gt 0 ] || return 0

  printf 'Debian packages: %s\n' "${pkgs[*]}"
  run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
}

# Debian installs fd as fdfind and bat as batcat. Link the names the configs
# (and doctor) expect into ~/.local/bin.
link_compat() {
  local src=$1 dst=$2 target
  command -v "$dst" >/dev/null 2>&1 && return 0
  target=$(command -v "$src" 2>/dev/null) || return 0

  if [ "$dry" -eq 1 ]; then
    printf 'would link %s -> %s\n' "$HOME/.local/bin/$dst" "$target"
    return 0
  fi

  mkdir -p "$HOME/.local/bin"
  ln -sf "$target" "$HOME/.local/bin/$dst"
  printf 'Linked %s -> %s\n' "$HOME/.local/bin/$dst" "$target"
}

print_extra() {
  local file="$ROOT/packages/extra.txt" cmd hint missing=0
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
  ids=""
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
  arch) install_arch || exit 1 ;;
  debian) install_debian || exit 1 ;;
  *)
    printf 'unsupported distribution; install from packages/arch.txt (pacman) or packages/debian.txt (apt)\n' >&2
    print_extra
    exit 1
    ;;
esac

link_compat fdfind fd
link_compat batcat bat
print_extra
