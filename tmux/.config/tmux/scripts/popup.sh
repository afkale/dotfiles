#!/usr/bin/env bash
# popup.sh — attach to the isolated popup session used by M-1.
#
# The popup runs on its own tmux socket, so the main config's keybindings and
# status bar do not leak into it. Only M-1 (detach/close) and M-v (copy-mode)
# are bound. The status bar is off.

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
# The popup server starts from /dev/null, so vi copy-mode is not inherited.
tmux -L "$SOCKET" set -g mode-keys vi
# No prefix at all, so nothing can get stuck waiting for the second key of a
# keybinding inside the popup.
tmux -L "$SOCKET" set -g prefix None
tmux -L "$SOCKET" set -g prefix2 None
tmux -L "$SOCKET" set -sg escape-time 10
tmux -L "$SOCKET" set -g allow-passthrough on
tmux -L "$SOCKET" unbind -a -T root
tmux -L "$SOCKET" unbind -a -T prefix
tmux -L "$SOCKET" bind -n M-v copy-mode
tmux -L "$SOCKET" bind -n M-1 detach-client
# Same vi copy-mode keys as conf/keys.tmux. y pipes to the system clipboard
# because the popup server has its own paste buffer.
tmux -L "$SOCKET" bind -T copy-mode-vi v send-keys -X begin-selection
tmux -L "$SOCKET" bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
tmux -L "$SOCKET" bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel \
  "wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || cat >/dev/null"
tmux -L "$SOCKET" bind -T copy-mode-vi Escape send-keys -X cancel

exec tmux -L "$SOCKET" attach -t "=$SESSION"
