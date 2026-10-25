# Core behaviour: prefix, numbering, terminal and history settings.

set -g prefix M-space
set -g mouse on
set -g status on
set -g status-position bottom

# Windows and panes both start at 1.
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

set -g history-file ~/.tmux_history
set -g mode-keys vi
set -g focus-events on
set -sg escape-time 10

set -a terminal-features "tmux-256color:RGB"
set -a terminal-overrides "tmux-256color:Tc"
