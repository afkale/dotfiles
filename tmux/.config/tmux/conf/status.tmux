# Status bar, message and popup styling.

set -g @logo " "
set -g @logofg "#e6d9ff"

set -g status-interval 1
set -g status-left " #[fg=#{@logofg}]#{@logo} #[fg=#9f8fbf]#S "
set -g status-right '#[fg=#9f8fbf]#(TZ="Europe/Madrid" date +%%H:%%M:%%S) '
set -g status-justify centre
set -g status-left-length 85
set -g status-right-length 85
set -g status-style bg=default

set -g window-status-current-format " #[fg=#e6d9ff]#W "
set -g window-status-format " #[fg=#9f8fbf]#W "

set -g message-command-style "bg=#1e1e2e,fg=#e6d9ff"
set -g message-style "bg=#1e1e2e,fg=#9f8fbf"

set -g popup-border-style "fg=#6C7086"
set -g popup-border-lines "rounded"
set -g popup-style "bg=#1e1e2e,fg=#CDD6F4"
