#!/usr/bin/env bash
# lib.sh — helpers shared by the tmux scripts in this directory.
#
# Sourced by pane.sh, sessions.sh, worktree.sh, ai.sh and streamux.sh.

# Popup sessions are named "_hidden*" and never show up in pickers.
is_hidden_session() {
  case "${1:-}" in
    _hidden*) return 0 ;;
    *) return 1 ;;
  esac
}

# Hooks and popups know their pane through TMUX_PANE; fall back to tmux.
current_pane() {
  if [ -n "${TMUX_PANE:-}" ]; then
    printf '%s\n' "$TMUX_PANE"
  else
    tmux display-message -p '#{pane_id}' 2>/dev/null
  fi
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

# Default location for small pieces of tmux state (pane/session/worktree/ai MRU).
tmux_state_dir() {
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
}

# Shared look for every fzf menu in these scripts (panes, sessions, worktrees,
# ai). Defining it once keeps the menus visually identical; callers add their
# own --border-label, --header, preview and key bindings on top.
# Shellcheck sees this file on its own, but the array is used by the scripts
# that source it.
# shellcheck disable=SC2034
FZF_STYLE=(
  --cycle
  --ansi
  --info=inline
  --border=rounded
  --color='fg:#908caa,bg:#191724,hl:#eb6f92,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92'
  --color='info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177'
  --color='header:#6e6a86,border:#403d52,label:#c4a7e7,selected-bg:#26233a'
)

# mru_push FILE ITEM [LIMIT]
#
# Move ITEM to the front of FILE, a newest-first list with one item per line.
# Duplicates are dropped and the list is capped at LIMIT entries. Writes are
# serialized with flock when available, so hooks can call this concurrently.
mru_push() {
  local file=${1:-} item=${2:-} limit=${3:-100} dir tmp
  [ -n "$file" ] && [ -n "$item" ] || return 0
  case "$item" in *$'\n'*|*$'\r'*) return 0 ;; esac

  dir=$(dirname "$file")
  mkdir -p "$dir" 2>/dev/null || return 0

  # Use a subshell so the lock fd is automatically closed when we return.
  (
    if command -v flock >/dev/null 2>&1; then
      exec 9>>"$file.lock"
      flock -w 1 9 2>/dev/null || true
    fi

    tmp=$(mktemp "$dir/.mru.XXXXXX") || exit 0
    {
      printf '%s\n' "$item"
      [ -f "$file" ] && cat "$file"
    } | awk -v limit="$limit" \
          'length($0) && !seen[$0]++ && count++ < limit' >"$tmp"
    mv -f "$tmp" "$file"
  )
}
