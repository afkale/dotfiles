#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/envs.sh"
source "$SCRIPT_DIR/helpers.sh"

case "$1" in
  next-window) tmux next-window ;;
  prev-window) tmux previous-window ;;
  next-session) tmux switch-client -n ;;
  prev-session) tmux switch-client -p ;;
esac

tmux_save_current_pane
