#!/usr/bin/env bash

tmux set -g @recording " #[fg=red]#[blink]󰑋"

pane=$(tmux display-message -p '#S:#W')
kitty asciinema stream -r -c "tmux attach -t $pane"
