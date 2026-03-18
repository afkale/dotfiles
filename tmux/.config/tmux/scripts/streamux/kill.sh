#!/usr/bin/env bash

if pgrep -l asciinema; then
  tmux set -g @logofg "#e6d9ff"

  killall asciinema
fi
