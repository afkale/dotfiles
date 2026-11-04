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

# Stamp the popup config version so we can skip reconfiguration on later opens.
# Bump this when changing the layout below; sessions with an older stamp (or no
# stamp) will be reconfigured once, then skip on subsequent M-1 opens.
POPUP_CONFIG_VERSION="popup-v1"
current_version=$(tmux -L "$SOCKET" show-option -gqv "@popup_config" 2>/dev/null || true)

if [ "$current_version" != "$POPUP_CONFIG_VERSION" ]; then
  # A single tmux round trip (rather than one client per option) keeps M-1
  # snappy. Also fixes a session left over from an older popup config.
  tmux -L "$SOCKET" \
    set -g status off \; \
    set -g mouse on \; \
    set -g mode-keys vi \; \
    set -g prefix None \; \
    set -g prefix2 None \; \
    set -sg escape-time 10 \; \
    set -g allow-passthrough on \; \
    set -g "@popup_config" "$POPUP_CONFIG_VERSION" \; \
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
fi

exec tmux -L "$SOCKET" attach -t "=$SESSION"
