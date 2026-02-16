#!/usr/bin/env bash

tmux set -g @logofg "red"

pane=$(tmux display-message -p '#S:#W')
kitty asciinema stream -r -c "tmux attach -t $pane"
