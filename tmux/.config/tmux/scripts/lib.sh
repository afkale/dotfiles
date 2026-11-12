#!/usr/bin/env bash
# lib.sh — helpers shared by the tmux scripts in this directory.
#
# Sourced by streamux.sh, task.sh and window.sh.

# Derive our own directory so palette.sh can be found from any sourcing context.
# shellcheck source-path=SCRIPTDIR source=palette.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/palette.sh"

# Popup sessions are named "_hidden*" and never show up in pickers.
is_hidden_session() {
  case "${1:-}" in
    _hidden*) return 0 ;;
    *) return 1 ;;
  esac
}

current_session_id() {
  tmux display-message -p '#{session_id}' 2>/dev/null
}

# Client attached to a given session (needed when several terminals are open).
client_for_session() {
  local session="${1:-}" sid name
  [ -n "$session" ] || return 0

  while IFS=$'\t' read -r sid name; do
    if [ "$sid" = "$session" ]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(tmux list-clients -F '#{session_id}'$'\t''#{client_name}' 2>/dev/null)
}

# Transient message inside tmux, plain text otherwise.
message() {
  if [ -n "${TMUX:-}" ]; then
    tmux display-message -d 1500 "$*" 2>/dev/null || true
  else
    printf '%s\n' "$*"
  fi
}

# Wait for a keypress when stderr is a terminal (inside a non-E popup).
# In -E popups stdin is not a tty, so this returns immediately. Callers that
# need to keep the popup visible on error must use hold_always instead.
hold() {
  [ -t 0 ] || return 0
  printf '\npress any key to close'
  IFS= read -rsn1 || true
  printf '\n'
}

# Like hold() but waits for input regardless of whether stdin is a tty.
# Use inside display-popup without the -E flag to keep errors visible.
hold_always() {
  printf '\npress any key to close'
  IFS= read -rsn1 || true
  printf '\n'
}

# Validate a branch/task name: alphanumeric, dots, underscores, slashes and
# hyphens only, must not start with a hyphen, must be a valid git ref.
validate_name() {
  local name=$1
  case "$name" in
    ''|*[!A-Za-z0-9._/-]*)
      message "invalid name: use letters, numbers, ., _, / or -"
      return 1
      ;;
    -*)
      message "invalid name: cannot start with -"
      return 1
      ;;
  esac
  if command -v git >/dev/null 2>&1; then
    git check-ref-format --branch "$name" >/dev/null 2>&1 || {
      message "invalid branch name: $name"
      return 1
    }
  fi
}

# Shared look for every fzf menu. Defining it once keeps the menus visually
# identical; callers add their own --border-label, --header, preview and key
# bindings on top.
# Shellcheck sees this file on its own, but the array is used by the scripts
# that source it.
# shellcheck disable=SC2034
FZF_STYLE=(
  --cycle
  --ansi
  --info=inline
  --border=rounded
  --color="fg:${PAL_SUBTLE_HEX},bg:${PAL_BASE_HEX},hl:${PAL_LOVE_HEX},fg+:${PAL_TEXT_HEX},bg+:${PAL_OVERLAY_HEX},hl+:${PAL_LOVE_HEX}"
  --color="info:${PAL_IRIS_HEX},prompt:${PAL_IRIS_HEX},pointer:${PAL_ROSE_HEX},marker:${PAL_FOAM_HEX},spinner:${PAL_GOLD_HEX}"
  --color="header:${PAL_MUTED_HEX},border:${PAL_HL_MED_HEX},label:${PAL_IRIS_HEX},selected-bg:${PAL_OVERLAY_HEX}"
)


