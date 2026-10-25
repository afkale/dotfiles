# Popups. -E closes the popup when the command exits.

# Terminal in the current directory
bind -n M-1 popup -d '#{pane_current_path}' -E -w 90% -h 90%

# Lazygit
bind -n M-g popup -B -d '#{pane_current_path}' -E -w 100% -h 100% lazygit

# Btop
bind -n M-p popup -B -d '#{pane_current_path}' -E -w 100% -h 100% btop

# Pane picker (MRU ordered)
bind -n M-d popup -B -d '#{pane_current_path}' -E -w 100% -h 100% "$PANE_SCRIPT pick"
