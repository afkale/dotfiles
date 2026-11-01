#!/usr/bin/env bash
# popup.sh — attach to the isolated popup session used by M-1.
#
# The popup runs on its own tmux socket, so the main config's keybindings and
# status bar do not leak into it. Only M-1 (detach/close), M-v (copy-mode) and
# the vi copy-mode keys from conf/keys.tmux are bound. The status bar is off.

set -u

SOCKET="${TMUX_POPUP_SOCKET:-tmux-popup}"
SESSION="${TMUX_POPUP_SESSION:-_hidden_popup}"

# display-popup inherits TMUX from the outer client; a nested attach needs it
# unset.
unset TMUX

if ! tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null; then
  tmux -L "$SOCKET" -f /dev/null new-session -d -s "$SESSION" -c "$PWD" || exit 1
fi

# Idempotent: also fixes a session left over from an older run. A single tmux
# round trip (rather than one client per option) keeps M-1 snappy, since this
# runs on every open.
tmux -L "$SOCKET" \
  set -g status off \; \
  set -g mouse on \; \
  set -g mode-keys vi \; \
  set -g prefix None \; \
  set -g prefix2 None \; \
  set -sg escape-time 10 \; \
  set -g allow-passthrough on \; \
  unbind -a -T root \; \
  bind -n M-v copy-mode \; \
  bind -n M-1 detach-client \; \
  bind -T copy-mode-vi v send-keys -X begin-selection \; \
  bind -T copy-mode-vi C-v send-keys -X rectangle-toggle \; \
  bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel \
    "wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || cat >/dev/null" \; \
  bind -T copy-mode-vi Escape send-keys -X cancel

# The prefix table disappears once emptied, so later opens hit "table prefix
# doesn't exist"; that is expected.
tmux -L "$SOCKET" unbind -a -T prefix 2>/dev/null || true

exec tmux -L "$SOCKET" attach -t "=$SESSION"
