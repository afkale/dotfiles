#!/usr/bin/env bash
# session.sh — create a project session managed by workmux (M-C-w).
#
#   session.sh create <cwd> <session-name>
#
# Called from the M-C-w key binding. The script creates a workmux session-mode
# worktree named after the base branch (main) and switches the client to it.
# Subsequent worktrees are added via M-s sidebar or workmux add.
#
# This replaces the old manual session creation. Workmux manages the session
# lifecycle, so worktrees can be placed in it with --parent-session.

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

create() {
  local cwd="${1:-}" session_name="${2:-}"
  [ -n "$session_name" ] || {
    message "session.sh: no session name given"
    return 1
  }

  # Let workmux create the session-mode worktree. This registers the session
  # with workmux so subsequent workmux add --parent-session <name> works.
  cd "$cwd" 2>/dev/null || {
    message "session.sh: can't access $cwd"
    return 1
  }

  if ! workmux add main --session "$session_name" --base main --background 2>/dev/null; then
    message "session.sh: workmux add failed"
    return 1
  fi

  # Switch the client to the new session.
  local client
  client=$(client_for_session "$(current_session_id)")
  if [ -n "$client" ]; then
    tmux switch-client -c "$client" -t "$session_name" 2>/dev/null || true
  else
    tmux switch-client -t "$session_name" 2>/dev/null || true
  fi
}

# Guard: only dispatch when executed directly, not sourced (for tests).
(return 0 2>/dev/null) && return 0

case "${1:-}" in
  create) shift; create "$@" ;;
  *)
    printf 'usage: %s create <cwd> <session-name>\n' "${0##*/}" >&2
    exit 2
    ;;
esac
