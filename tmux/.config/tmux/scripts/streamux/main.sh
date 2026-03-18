#!/usr/bin/env bash

if [ ! $(pgrep -l asciinema) ]; then
  tmux set -g @logofg "red"

  pane=$(tmux display-message -p '#S:#W')
  ghostty -e asciinema stream -r -c "tmux attach -t $pane"
fi
