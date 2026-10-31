#!/usr/bin/env bash
# doctor.sh — check that this machine can run the dotfiles as configured.
#
# Checks tools, stow links, the nvim submodule and config syntax. Exits non-zero
# when something is actually broken; optional tools only produce a warning.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# Homebrew on Linux is how deps.sh installs newer tools on Debian/Ubuntu.
for brew_bin in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done

# deps.sh links fdfind/batcat (Debian names) into ~/.local/bin. Fish adds that
# directory to PATH, but doctor may run from bash, so add it here as well.
# Keep it ahead of Homebrew so the Debian compatibility links win.
PATH="$HOME/.local/bin:$PATH"
export PATH

fail=0
ok()      { printf '  \033[32mok\033[0m   %s\n' "$*"; }
warn()    { printf '  \033[33mwarn\033[0m %s\n' "$*"; }
bad()     { printf '  \033[31mfail\033[0m %s\n' "$*"; fail=1; }
section() { printf '\n%s\n' "$*"; }

section "tools"
required="git stow fish tmux nvim fzf fd rg bat lsd zoxide jq lazygit btop asciinema yazi less python3 ghostty"
for cmd in $required; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    bad "$cmd missing (make deps)"
  fi
done

for cmd in shellcheck delta fastfetch; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    warn "$cmd missing (optional)"
  fi
done

if command -v opencode >/dev/null 2>&1; then
  ok "opencode"
else
  warn "opencode missing (install separately)"
fi

section "versions"

version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]
}

# Print the first dotted version found in the tool's banner. The banners differ
# ("NVIM v0.12.6", "0.74.5 (abcdef)", "tmux 3.8"), so extract instead of parsing.
check_version() {
  local cmd=$1 min=$2 raw have
  command -v "$cmd" >/dev/null 2>&1 || return 0

  case "$cmd" in
    nvim)      raw=$(nvim --version 2>/dev/null | head -1) ;;
    fzf)       raw=$(fzf --version 2>/dev/null) ;;
    asciinema) raw=$(asciinema --version 2>/dev/null) ;;
    tmux)      raw=$(tmux -V 2>/dev/null) ;;
  esac

  have=$(printf '%s\n' "$raw" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
  if [ -z "$have" ]; then
    warn "$cmd version unknown (want >= $min)"
  elif version_ge "$min" "$have"; then
    ok "$cmd $have"
  else
    bad "$cmd $have is too old (want >= $min; see packages/extra.txt)"
  fi
}

check_version nvim 0.12
check_version fzf 0.48
check_version asciinema 3.0
check_version tmux 3.3

section "submodules"
if [ ! -f .gitmodules ]; then
  ok "no submodules"
else
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    rest=${line#?}
    path=${rest#* }
    path=${path% (*}
    case "$line" in
      -*) bad "$path not initialized (make setup)" ;;
      +*) warn "$path differs from the parent gitlink (make update)" ;;
      U*) bad "$path has merge conflicts" ;;
      *)  ok "$path" ;;
    esac
  done < <(git submodule status --recursive 2>/dev/null)
fi

section "stow links"

# Every tracked file must resolve back into this repository. Folded
# directories (stow's default) still resolve correctly through realpath.
link_pkg() {
  local pkg=$1 rel target count=0 missing=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    count=$((count + 1))
    target="$HOME/${rel#"$pkg"/}"
    if [ ! -e "$target" ] || [ "$(realpath "$target" 2>/dev/null)" != "$(realpath "$ROOT/$rel" 2>/dev/null)" ]; then
      # shellcheck disable=SC2088 # ~ is shown for readability, not expanded
      [ "$missing" -lt 3 ] && bad "~/${rel#"$pkg"/} is not linked"
      missing=$((missing + 1))
    fi
  done < <(git ls-files -- "$pkg")
  if [ "$missing" -eq 0 ]; then
    ok "$pkg ($count files)"
  else
    bad "$pkg: $missing file(s) not linked (make link-dotfiles)"
  fi
}

for pkg in fish ghostty lazygit tmux wallpapers opencode; do
  link_pkg "$pkg"
done

# nvim is a submodule, so the parent only tracks the gitlink.
if [ -e "$HOME/.config/nvim/init.lua" ] &&
  [ "$(realpath "$HOME/.config/nvim" 2>/dev/null)" = "$(realpath "$ROOT/nvim/.config/nvim" 2>/dev/null)" ]; then
  ok "nvim (submodule)"
else
  # shellcheck disable=SC2088 # ~ is shown for readability, not expanded
  bad "~/.config/nvim is not linked (make link-dotfiles)"
fi

section "syntax"
bash_ok=1
while IFS= read -r -d '' file; do
  if ! bash -n "$file" 2>/dev/null; then
    bad "bash: $file"
    bash_ok=0
  fi
done < <(find . -name .git -prune -o -name '*.sh' -print0)
[ "$bash_ok" -eq 1 ] && ok "bash scripts"

if command -v fish >/dev/null 2>&1; then
  fish_ok=1
  while IFS= read -r -d '' file; do
    if ! fish -n "$file" 2>/dev/null; then
      bad "fish: $file"
      fish_ok=0
    fi
  done < <(find fish -name '*.fish' -print0)
  [ "$fish_ok" -eq 1 ] && ok "fish functions"
fi

if [ -e "$HOME/.config/nvim/init.lua" ] && command -v nvim >/dev/null 2>&1; then
  if timeout 30 nvim --headless +qa >/dev/null 2>&1; then
    ok "nvim startup"
  else
    bad "nvim failed to start (nvim --headless +qa)"
  fi
else
  warn "nvim not linked; skipping startup check"
fi

if [ -e "$HOME/.config/tmux/tmux.conf" ] && command -v tmux >/dev/null 2>&1; then
  sock="dotfiles-doctor-$$"
  err=$(mktemp)
  if tmux -L "$sock" -f "$HOME/.config/tmux/tmux.conf" new-session -d -s doctor 2>"$err"; then
    if [ -s "$err" ]; then
      bad "tmux config reported errors:"
      sed 's/^/       /' "$err"
    else
      ok "tmux config"
    fi
  else
    bad "tmux config failed to load:"
    sed 's/^/       /' "$err"
  fi
  tmux -L "$sock" kill-server 2>/dev/null || true
  rm -f "$err"
else
  warn "tmux not linked; skipping config check"
fi

printf '\n'
if [ "$fail" -eq 0 ]; then
  printf 'all checks passed\n'
else
  printf 'some checks failed\n'
fi
exit "$fail"
