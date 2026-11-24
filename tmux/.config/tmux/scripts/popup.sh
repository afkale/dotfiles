#!/usr/bin/env bash
# popup.sh — attach to the isolated popup session (M-1).
#
# The popup runs on its own tmux socket with its own minimal config, so the
# main config's keybindings and status bar do not leak into it. Only M-1 is
# bound (it detaches, which closes the popup), and the status bar is off.
#
# Use:
#   bind -n M-1 display-popup -d '#{pane_current_path}' -xC -yC \
#     -w 80% -h 75% -E "$POPUP_SCRIPT"

set -u

SOCKET="${TMUX_POPUP_SOCKET:-tmux-popup}"
SESSION="${TMUX_POPUP_SESSION:-_hidden_popup}"

# display-popup inherits TMUX from the outer client; a nested attach needs it
# unset.
unset TMUX

if ! tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
  tmux -L "$SOCKET" -f /dev/null new-session -d -s "$SESSION" -c "$PWD" || exit 1
fi

# Apply minimal settings idempotently. The session is destroyed when the last
# client detaches, so the next open starts a fresh shell in the directory it
# is opened from.
tmux -L "$SOCKET" set-hook -t "$SESSION" client-detached "kill-session -t '$SESSION'" 2>/dev/null || true
tmux -L "$SOCKET" set -g status off
tmux -L "$SOCKET" set -g mouse on
tmux -L "$SOCKET" unbind -a -T root
tmux -L "$SOCKET" unbind -a -T prefix
tmux -L "$SOCKET" bind -n M-1 detach-client
tmux -L "$SOCKET" set -g mode-keys vi
tmux -L "$SOCKET" bind -n M-v copy-mode
tmux -L "$SOCKET" bind -T copy-mode-vi v send-keys -X begin-selection
tmux -L "$SOCKET" bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
tmux -L "$SOCKET" bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel \
  "wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || cat >/dev/null"
tmux -L "$SOCKET" bind -T copy-mode-vi Escape send-keys -X cancel

exec tmux -L "$SOCKET" attach -t "=$SESSION"
