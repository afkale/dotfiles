#!/usr/bin/env bash
# streamux.sh — toggle the asciinema session recording used by M-s / M-C-s.

set -u

case "${1:-}" in
  start)
    if ! pgrep -x asciinema >/dev/null 2>&1; then
      tmux set -g @logofg "#eb6f92"
      session=$(tmux display-message -p '#{session_name}')
      # The new terminal inherits TMUX, so drop it before attaching.
      ghostty -e asciinema stream -r -c "env -u TMUX tmux attach -t '$session'"
    fi
    ;;
  stop)
    # Reset the logo even if the recorder already exited.
    tmux set -g @logofg "#c4a7e7"
    if pgrep -x asciinema >/dev/null 2>&1; then
      killall asciinema
    fi
    ;;
  *)
    printf 'usage: %s {start|stop}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
