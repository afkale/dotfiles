# Popups. -E closes the popup when the command exits.

# Isolated popup. It has its own tmux socket, so only M-1 is bound there and
# the status bar is hidden (see scripts/popup.sh).
bind -n M-1 display-popup -d '#{pane_current_path}' -xC -yC -w 80% -h 75% -E "$POPUP_SCRIPT"

# Session picker
bind -n M-s display-popup -B -E -w 90% -h 80% "$SESSIONS_SCRIPT pick"

# Key cheatsheet: everything tmux knows, searchable.
bind -n M-? display-popup -B -E -w 90% -h 80% "tmux list-keys | fzf --reverse --header='type to filter · esc: close'"

# Yazi
bind -n M-y display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  yazi ' yazi

# Lazygit
bind -n M-g display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  lazygit ' lazygit

# Btop
bind -n M-p display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  btop ' btop

bind -n M-d if-shell "$PANE_SCRIPT has '#{pane_id}'" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$PANE_SCRIPT pick'" \
  "display-message -d 1500 'no other panes'"

bind -n M-o if-shell "$PANE_SCRIPT has '#{pane_id}' opencode" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$PANE_SCRIPT pick opencode'" \
  "display-message -d 1500 'no opencode panes'"

bind -n M-n if-shell "$PANE_SCRIPT has '#{pane_id}' nvim" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$PANE_SCRIPT pick nvim'" \
  "display-message -d 1500 'no nvim panes'"

# ai run prompt picker (commands from run-commands.json)
bind -n M-c if-shell "$AI_SCRIPT has" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$AI_SCRIPT pick'" \
  "display-message -d 1500 'no ai commands'"
