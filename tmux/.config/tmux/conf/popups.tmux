# Popups. -E closes the popup when the command exits.

# In ~/.tmux.conf
bind-key -n M-1 if-shell -F '#{==:#{session_name},_hidden_popup}' {
    detach-client
} {
    display-popup -d '#{pane_current_path}' -xC -yC -w 80% -h 75% -E "env -u TMUX tmux attach -t _hidden_popup || env -u TMUX tmux new-session -s _hidden_popup"
}

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

# opencode run prompt picker (commands from run-commands.json)
bind -n M-c if-shell "$OPENCODE_SCRIPT has" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$OPENCODE_SCRIPT pick'" \
  "display-message -d 1500 'no run commands'"
