# Popups. -E closes the popup when the command exits.

# Terminal in the current directory
bind -n M-1 popup -d '#{pane_current_path}' -E -w 90% -h 90%

# Lazygit
bind -n M-g popup -B -d '#{pane_current_path}' -E -w 100% -h 100% lazygit

# Btop
bind -n M-p popup -B -d '#{pane_current_path}' -E -w 100% -h 100% btop

bind -n M-d if-shell "$PANE_SCRIPT has '#{pane_id}'" \
  "display-popup -B -E -d '#{pane_current_path}' -w 100% -h 100% '$PANE_SCRIPT pick'" \
  "display-message -d 1500 'no other panes'"

bind -n M-o if-shell "$PANE_SCRIPT has '#{pane_id}' opencode" \
  "display-popup -B -E -d '#{pane_current_path}' -w 100% -h 100% '$PANE_SCRIPT pick opencode'" \
  "display-message -d 1500 'no opencode panes'"

bind -n M-n if-shell "$PANE_SCRIPT has '#{pane_id}' nvim" \
  "display-popup -B -E -d '#{pane_current_path}' -w 100% -h 100% '$PANE_SCRIPT pick nvim'" \
  "display-message -d 1500 'no nvim panes'"
