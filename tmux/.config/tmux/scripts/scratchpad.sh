#!/usr/bin/env bash
# scratchpad.sh — toggle a persistent scratch window in the current session.
#
# Bound to M-` in tmux.conf. If a window named "scratch" exists, switch to it
# (or back to the previous window if already there). Otherwise create one
# running nvim in the current pane's directory.

set -u

SESSION=$(tmux display-message -p '#{session_name}')
CURRENT=$(tmux display-message -p '#{window_name}')
CWD=$(tmux display-message -p '#{pane_current_path}')

if [ "$CURRENT" = "scratch" ]; then
  # Already in scratch: go back to the previous window.
  tmux last-window 2>/dev/null || true
  exit 0
fi

if tmux list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null | grep -qx 'scratch'; then
  tmux select-window -t "$SESSION:scratch" 2>/dev/null || true
  exit 0
fi

# Create the scratch window.
tmux new-window -t "$SESSION" -n scratch -c "$CWD" nvim 2>/dev/null || \
  tmux new-window -t "$SESSION" -n scratch -c "$CWD"
