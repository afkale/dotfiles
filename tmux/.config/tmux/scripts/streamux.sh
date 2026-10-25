#!/usr/bin/env bash
# streamux.sh — toggle the asciinema session recording used by M-s / M-C-s.

set -u

case "${1:-}" in
  start)
    if ! pgrep -x asciinema >/dev/null 2>&1; then
      tmux set -g @logofg red
      session=$(tmux display-message -p '#{session_name}')
      ghostty -e asciinema stream -r -c "tmux attach -t '$session'"
    fi
    ;;
  stop)
    if pgrep -x asciinema >/dev/null 2>&1; then
      tmux set -g @logofg "#e6d9ff"
      killall asciinema
    fi
    ;;
  *)
    printf 'usage: %s {start|stop}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
