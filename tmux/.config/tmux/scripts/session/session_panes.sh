#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/envs.sh"
source "$SCRIPT_DIR/helpers.sh"

main() {
  current_pane=$(tmux_get_current_session_pane)
  last_pane=$(tmux_get_last_session_pane)
  panes=$(tmux_get_panes)


  if [ -n "$last_pane" ]; then
    panes=$(printf '%s\n' "$panes" | awk -v lp="$last_pane" '$0 != lp; BEGIN {print lp}')
  fi

  if [ -n "$current_pane" ]; then
    panes=$(printf '%s\n' "$panes" | grep -v "$current_pane")
  fi

  printf '%s\n' "$panes"
}
main
