#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/envs.sh"
source "$SCRIPT_DIR/helpers.sh"

main() {
  touch "$FZF_SESSION_HISTORY"

  result=$(
     $SCRIPT_DIR/session_panes.sh | fzf \
      --with-nth=1,2,3,4,5 \
      --preview "tmux capture-pane -t {1} -p -e -S -100 | tail -n 48" \
      --bind "ctrl-x:execute(tmux kill-pane -t {1})+reload($SCRIPT_DIR/session_panes.sh)" \
      --bind "ctrl-r:refresh-preview+reload($SCRIPT_DIR/session_panes.sh)" \
      --bind "enter:become(echo {1} {2} {3} {4} {5})"
  )

  [ -z "$result" ] && exit 0
  tmux switchc -t "$(echo "$result" | awk -F' - ' '{print $1}' | xargs)"

  tmux_save_current_pane
  tmux_clean_session_panes
}
main
