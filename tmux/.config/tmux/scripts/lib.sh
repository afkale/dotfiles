#!/usr/bin/env bash
# lib.sh — helpers shared by the tmux scripts in this directory.
#
# Sourced by pane.sh, sessions.sh and streamux.sh. Keep it dependency-free so
# it also works when invoked from a bare tmux server or a hook.

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
