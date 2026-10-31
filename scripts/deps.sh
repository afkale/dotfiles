#!/usr/bin/env bash
# deps.sh — install the packages the configs expect on Arch or Debian/Ubuntu.
#
# Arch-family systems use packages/arch.txt (pacman). Debian-family systems
# use packages/debian.txt (apt) for stable basics, then install the
# version-sensitive tools from their official upstream releases into
# ~/.local/bin because distro packages are often too old.
#
#   scripts/deps.sh             install for this machine
#   scripts/deps.sh --dry-run   print what would be installed

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"
UPSTREAM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/upstream"

# Prefer tools we installed over distro copies.
PATH="$BIN_DIR:$PATH"
export PATH

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

  mapfile -t pkgs < <(read_pkgs "$list")
  [ "${#pkgs[@]}" -gt 0 ] || return 0

  say "Arch packages: ${pkgs[*]}"
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

version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]
}

tool_version() {
  local raw=''
  case "$1" in
    nvim)      raw=$(nvim --version 2>/dev/null | head -1) ;;
    fzf)       raw=$(fzf --version 2>/dev/null) ;;
    asciinema) raw=$(asciinema --version 2>/dev/null) ;;
    tmux)      raw=$(tmux -V 2>/dev/null) ;;
    lsd)       raw=$(lsd --version 2>/dev/null) ;;
  esac
  printf '%s\n' "$raw" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1
}

# True when the command is missing or older than the required version.
needs_tool() {
  local cmd=$1 min=$2 have
  command -v "$cmd" >/dev/null 2>&1 || return 0
  have=$(tool_version "$cmd")
  [ -n "$have" ] || return 0
  ! version_ge "$min" "$have"
}

rel_tag=''
rel_url=''
release_lookup() {
  local repo=$1 asset=$2 json
  rel_tag=''
  rel_url=''

  json=$(curl -fsSL --retry 3 "https://api.github.com/repos/$repo/releases/latest") || return 1
  rel_tag=$(printf '%s' "$json" | jq -r '.tag_name // empty')
  rel_url=$(printf '%s' "$json" | jq -r --arg n "$asset" \
    '.assets[] | select(.name == $n) | .browser_download_url' | head -1)

  [ -n "$rel_tag" ] && [ -n "$rel_url" ]
}

fetch_archive() {
  local url=$1 dir=$2 file
  file="$dir/$(basename "$url")"

  curl -fsSL --retry 3 -o "$file" "$url" || return 1
  case "$file" in
    *.tar.gz|*.tgz) tar -xzf "$file" -C "$dir" ;;
    *.zip)          unzip -q "$file" -d "$dir" ;;
    *)              return 1 ;;
  esac
}

install_bin() {
  local dir=$1 bin=$2 found
  found=$(find "$dir" -type f -name "$bin" | head -1)
  [ -n "$found" ] || {
    warn "could not find $bin in the archive"
    return 1
  }

  mkdir -p "$BIN_DIR"
  install -m 755 "$found" "$BIN_DIR/$bin"
}

install_nvim() {
  local tag asset tmp root
  if ! needs_tool nvim 0.12; then
    say "nvim $(tool_version nvim) already installed"
    return 0
  fi

  case "$(uname -m)" in
    x86_64|amd64)  asset='nvim-linux-x86_64.tar.gz' ;;
    aarch64|arm64) asset='nvim-linux-arm64.tar.gz' ;;
    *) warn "unsupported architecture for nvim: $(uname -m)"; return 1 ;;
  esac

  release_lookup neovim/neovim "$asset" || {
    warn 'could not find the nvim release'
    return 1
  }
  tag=$rel_tag

  if [ "$dry" -eq 1 ]; then
    say "would install nvim $tag to $UPSTREAM_DIR/nvim"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! fetch_archive "$rel_url" "$tmp"; then
    rm -rf "$tmp"
    return 1
  fi

  root=$(find "$tmp" -type f -path '*/bin/nvim' | head -1)
  if [ -z "$root" ]; then
    rm -rf "$tmp"
    warn 'could not find the nvim tree in the archive'
    return 1
  fi
  root=$(dirname "$(dirname "$root")")

  mkdir -p "$UPSTREAM_DIR" "$BIN_DIR"
  rm -rf "$UPSTREAM_DIR/nvim"
  cp -a "$root" "$UPSTREAM_DIR/nvim"
  ln -sfn "$UPSTREAM_DIR/nvim/bin/nvim" "$BIN_DIR/nvim"
  rm -rf "$tmp"

  say "installed nvim $tag"
}

install_fzf() {
  local tag ver asset tmp
  if ! needs_tool fzf 0.48; then
    say "fzf $(tool_version fzf) already installed"
    return 0
  fi

  tag=$(curl -fsSL --retry 3 "https://api.github.com/repos/junegunn/fzf/releases/latest" |
    jq -r '.tag_name // empty') || tag=''
  [ -n "$tag" ] || {
    warn 'could not find the fzf release'
    return 1
  }
  ver=${tag#v}

  case "$(uname -m)" in
    x86_64|amd64)  asset="fzf-${ver}-linux_amd64.tar.gz" ;;
    aarch64|arm64) asset="fzf-${ver}-linux_arm64.tar.gz" ;;
    *) warn "unsupported architecture for fzf: $(uname -m)"; return 1 ;;
  esac

  release_lookup junegunn/fzf "$asset" || {
    warn "could not find the fzf asset: $asset"
    return 1
  }

  if [ "$dry" -eq 1 ]; then
    say "would install fzf $tag"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! fetch_archive "$rel_url" "$tmp" || ! install_bin "$tmp" fzf; then
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"

  say "installed fzf $tag"
}

install_asciinema() {
  local tag asset url
  if ! needs_tool asciinema 3.0; then
    say "asciinema $(tool_version asciinema) already installed"
    return 0
  fi

  case "$(uname -m)" in
    x86_64|amd64)  asset='asciinema-x86_64-unknown-linux-gnu' ;;
    aarch64|arm64) asset='asciinema-aarch64-unknown-linux-gnu' ;;
    *) warn "unsupported architecture for asciinema: $(uname -m)"; return 1 ;;
  esac

  release_lookup asciinema/asciinema "$asset" || {
    warn 'could not find the asciinema release'
    return 1
  }
  tag=$rel_tag
  url=$rel_url

  if [ "$dry" -eq 1 ]; then
    say "would install asciinema $tag"
    return 0
  fi

  mkdir -p "$BIN_DIR"
  if ! curl -fsSL --retry 3 -o "$BIN_DIR/asciinema" "$url"; then
    return 1
  fi
  chmod 755 "$BIN_DIR/asciinema"

  say "installed asciinema $tag"
}

install_lazygit() {
  local tag ver asset tmp
  if command -v lazygit >/dev/null 2>&1; then
    say 'lazygit already installed'
    return 0
  fi

  tag=$(curl -fsSL --retry 3 "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
    jq -r '.tag_name // empty') || tag=''
  [ -n "$tag" ] || {
    warn 'could not find the lazygit release'
    return 1
  }
  ver=${tag#v}

  case "$(uname -m)" in
    x86_64|amd64)  asset="lazygit_${ver}_linux_x86_64.tar.gz" ;;
    aarch64|arm64) asset="lazygit_${ver}_linux_arm64.tar.gz" ;;
    *) warn "unsupported architecture for lazygit: $(uname -m)"; return 1 ;;
  esac

  release_lookup jesseduffield/lazygit "$asset" || {
    warn "could not find the lazygit asset: $asset"
    return 1
  }

  if [ "$dry" -eq 1 ]; then
    say "would install lazygit $tag"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! fetch_archive "$rel_url" "$tmp" || ! install_bin "$tmp" lazygit; then
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"

  say "installed lazygit $tag"
}

install_yazi() {
  local tag asset tmp
  if command -v yazi >/dev/null 2>&1 && command -v ya >/dev/null 2>&1; then
    say 'yazi already installed'
    return 0
  fi

  case "$(uname -m)" in
    x86_64|amd64)  asset='yazi-x86_64-unknown-linux-gnu.zip' ;;
    aarch64|arm64) asset='yazi-aarch64-unknown-linux-gnu.zip' ;;
    *) warn "unsupported architecture for yazi: $(uname -m)"; return 1 ;;
  esac

  release_lookup sxyazi/yazi "$asset" || {
    warn 'could not find the yazi release'
    return 1
  }
  tag=$rel_tag

  if [ "$dry" -eq 1 ]; then
    say "would install yazi $tag"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! fetch_archive "$rel_url" "$tmp" || ! install_bin "$tmp" yazi || ! install_bin "$tmp" ya; then
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"

  say "installed yazi $tag"
}

install_lsd() {
  local tag ver asset tmp
  if ! needs_tool lsd 1.1; then
    say "lsd $(tool_version lsd) already installed"
    return 0
  fi

  tag=$(curl -fsSL --retry 3 "https://api.github.com/repos/lsd-rs/lsd/releases/latest" |
    jq -r '.tag_name // empty') || tag=''
  [ -n "$tag" ] || {
    warn 'could not find the lsd release'
    return 1
  }
  ver=${tag#v}

  case "$(uname -m)" in
    x86_64|amd64)  asset="lsd-v${ver}-x86_64-unknown-linux-gnu.tar.gz" ;;
    aarch64|arm64) asset="lsd-v${ver}-aarch64-unknown-linux-gnu.tar.gz" ;;
    *) warn "unsupported architecture for lsd: $(uname -m)"; return 1 ;;
  esac

  release_lookup lsd-rs/lsd "$asset" || {
    warn "could not find the lsd asset: $asset"
    return 1
  }

  if [ "$dry" -eq 1 ]; then
    say "would install lsd $tag"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! fetch_archive "$rel_url" "$tmp" || ! install_bin "$tmp" lsd; then
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"

  say "installed lsd $tag"
}

install_opencode() {
  local tag asset tmp
  if command -v opencode >/dev/null 2>&1; then
    say 'opencode already installed'
    return 0
  fi

  case "$(uname -m)" in
    x86_64|amd64)  asset='opencode-linux-x64.tar.gz' ;;
    aarch64|arm64) asset='opencode-linux-arm64.tar.gz' ;;
    *) warn "unsupported architecture for opencode: $(uname -m)"; return 1 ;;
  esac

  release_lookup sst/opencode "$asset" || {
    warn 'could not find the opencode release'
    return 1
  }
  tag=$rel_tag

  if [ "$dry" -eq 1 ]; then
    say "would install opencode $tag"
    return 0
  fi

  tmp=$(mktemp -d) || return 1
  if ! fetch_archive "$rel_url" "$tmp" || ! install_bin "$tmp" opencode; then
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"

  say "installed opencode $tag"
}

# tmux has no official binary release, so build it only when apt is too old.
install_tmux() {
  local tag ver tmp
  if ! needs_tool tmux 3.3; then
    say "tmux $(tool_version tmux) already installed"
    return 0
  fi

  if [ "$dry" -eq 1 ]; then
    say 'would build tmux >= 3.3 from source (needs build-essential, libevent-dev, libncurses-dev)'
    return 0
  fi

  run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential libevent-dev libncurses-dev bison pkg-config || return 1

  tag=$(curl -fsSL --retry 3 "https://api.github.com/repos/tmux/tmux/releases/latest" |
    jq -r '.tag_name // empty') || tag=''
  [ -n "$tag" ] || {
    warn 'could not find the tmux release'
    return 1
  }
  ver=${tag#v}

  tmp=$(mktemp -d) || return 1
  if ! curl -fsSL --retry 3 -o "$tmp/tmux.tar.gz" \
    "https://github.com/tmux/tmux/releases/download/${tag}/tmux-${ver}.tar.gz" ||
    ! tar -xzf "$tmp/tmux.tar.gz" -C "$tmp" ||
    ! (cd "$tmp/tmux-$ver" && ./configure --prefix="$UPSTREAM_DIR/tmux" &&
      make -j"$(nproc)" && make install); then
    rm -rf "$tmp"
    warn 'tmux build failed'
    return 1
  fi
  rm -rf "$tmp"

  ln -sfn "$UPSTREAM_DIR/tmux/bin/tmux" "$BIN_DIR/tmux"
  say "installed tmux $tag"
}

install_upstream() {
  local fail=0
  for tool in nvim fzf asciinema lazygit yazi lsd opencode tmux; do
    "install_$tool" || fail=1
  done
  return "$fail"
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

  # On Debian the upstream installers above handle these; only list what is
  # still missing after a real run.
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
    for cmd in curl jq tar unzip; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        warn "missing $cmd; install it before upstream tools"
        exit 1
      fi
    done
    install_upstream || exit 1
    link_compat fdfind fd
    link_compat batcat bat
    ;;
  *)
    warn 'unsupported distribution; install from packages/arch.txt (pacman) or packages/debian.txt (apt)'
    print_extra
    exit 1
    ;;
esac

print_extra
