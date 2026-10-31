# Core behaviour: prefix, numbering, terminal and history settings.

set -g prefix M-space
set -g mouse on
set -g status on
set -g status-position bottom

# Windows and panes both start at 1.
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Keep bells silent; the flag is still set for the pane picker.
set -g bell-action none

run-shell -b 'mkdir -p "$HOME/.local/state/tmux"'
set -g history-file ~/.local/state/tmux/history
set -g mode-keys vi
set -g focus-events on
set -sg escape-time 10

set -a terminal-features "tmux-256color:RGB"
set -a terminal-overrides "tmux-256color:Tc"

# Let programs (yazi) query the real terminal through tmux. Without this tmux
# swallows the query, so yazi waits out its 5s probe timeout on every quit.
set -g allow-passthrough on
set -ga update-environment TERM
set -ga update-environment TERM_PROGRAM
