#!/usr/bin/env bash
# popup.sh — attach to the isolated popup session used by M-1.
#
# The popup runs on its own tmux socket, so the main config's keybindings and
# status bar do not leak into it. Only M-1 is bound (it detaches, which closes
# the popup), and the status bar is off.

set -u

SOCKET="${TMUX_POPUP_SOCKET:-tmux-popup}"
SESSION="${TMUX_POPUP_SESSION:-_hidden_popup}"

# display-popup inherits TMUX from the outer client; a nested attach needs it
# unset.
unset TMUX

if ! tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
  tmux -L "$SOCKET" -f /dev/null new-session -d -s "$SESSION" -c "$PWD" || exit 1
fi

# Idempotent: also fixes a session left over from an older run.
tmux -L "$SOCKET" set -g status off
tmux -L "$SOCKET" set -g mouse on
tmux -L "$SOCKET" unbind -a -T root
tmux -L "$SOCKET" unbind -a -T prefix
tmux -L "$SOCKET" bind -n M-1 detach-client

exec tmux -L "$SOCKET" attach -t "=$SESSION"
