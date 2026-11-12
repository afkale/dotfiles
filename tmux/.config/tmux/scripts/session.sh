#!/usr/bin/env bash
# session.sh — create a project session with the workmux sidebar (M-C-w).
#
#   session.sh create <cwd> <session-name> <window-name>
#
# Called from a tmux command-prompt chain that collects the session and window
# names. THe script creates the session, starts the project-scoped sidebar, and
# switches the client to it.
#
# The sidebar is the primary surface for managing agents in a project session.
# It replaces the old M-W popup-based task creation.

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

create() {
  local cwd="${1:-}" session_name="${2:-}" window_name="${3:-code}"
  [ -n "$session_name" ] || {
    message "session.sh: no session name given"
    return 1
  }

  # Create the session detached, rename it and its first window.
  local session_id
  session_id=$(tmux new-session -d -c "$cwd" -P -F '#{session_id}' 2>/dev/null) || {
    message "failed to create session"
    return 1
  }

  tmux rename-session -t "$session_id" "$session_name" 2>/dev/null
  tmux rename-window -t "${session_id}:1" "$window_name" 2>/dev/null

  # Switch the client to the new session.
  local client
  client=$(client_for_session "$(current_session_id)")
  if [ -n "$client" ]; then
    tmux switch-client -c "$client" -t "$session_id" 2>/dev/null || true
  else
    tmux switch-client -t "$session_id" 2>/dev/null || true
  fi
}

# Guard: only dispatch when executed directly, not sourced (for tests).
(return 0 2>/dev/null) && return 0

case "${1:-}" in
  create) shift; create "$@" ;;
  *)
    printf 'usage: %s create <cwd> <session-name> [<window-name>]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
