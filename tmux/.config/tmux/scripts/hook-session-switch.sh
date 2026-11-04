#!/usr/bin/env bash
# hook-session-switch.sh — combined hook for client-session-changed.
#
# Replaces two separate hook commands (pane.sh save + sessions.sh record-id)
# with a single script so only one shell process is spawned per session switch.
#
# Usage in hooks.tmux:
#   set-hook -g client-session-changed \
#     "run-shell -b '$TMUX_SCRIPTS/hook-session-switch #{pane_id} #{session_id}'"

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

pane_id="${1:-}"
session_id="${2:-}"

# Record the pane in MRU (for the M-d pane picker).
if [ -n "$pane_id" ]; then
  "$SCRIPT_DIR/pane.sh" save "$pane_id"
fi

# Record the session in MRU (for the M-s session picker).
if [ -n "$session_id" ]; then
  "$SCRIPT_DIR/sessions.sh" record-id "$session_id"
fi
