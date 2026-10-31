# Popups. -E closes the popup when the command exits.

# Isolated popup. It has its own tmux socket, so only M-1 is bound there and
# the status bar is hidden (see scripts/popup.sh).
bind -n M-1 display-popup -d '#{pane_current_path}' -xC -yC -w 80% -h 75% -E "$POPUP_SCRIPT"

# Scratch shell. The session is hidden from pane/session searches.
bind -n M-t if-shell -F '#{==:#{session_name},_hidden_scratch}' {
    detach-client
} {
    display-popup -d '#{pane_current_path}' -xC -yC -w 80% -h 60% -E "env -u TMUX tmux attach -t _hidden_scratch || env -u TMUX tmux new-session -s _hidden_scratch"
}

# Session picker
bind -n M-s display-popup -B -E -w 90% -h 80% "$SESSIONS_SCRIPT pick"

# Key cheatsheet: everything tmux knows, searchable.
bind -n M-? display-popup -B -E -w 90% -h 80% "tmux list-keys | fzf --reverse --header='type to filter · esc: close'"

# Yazi — read a char after exit to absorb any key that would otherwise leak to
# the outer session's prefix-q (display-panes).
bind -n M-y display-popup -d '#{pane_current_path}' -xC -yC -w 100% -h 100% -E \
  "yazi; read -n 1 -t 0.2 2>/dev/null || true"

# Lazygit
bind -n M-g popup -B -d '#{pane_current_path}' -E -w 100% -h 100% lazygit

# Btop
bind -n M-p popup -B -d '#{pane_current_path}' -E -w 100% -h 100% btop

bind -n M-d if-shell "$PANE_SCRIPT has '#{pane_id}'" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$PANE_SCRIPT pick'" \
  "display-message -d 1500 'no other panes'"

bind -n M-o if-shell "$PANE_SCRIPT has '#{pane_id}' opencode" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$PANE_SCRIPT pick opencode'" \
  "display-message -d 1500 'no opencode panes'"

bind -n M-n if-shell "$PANE_SCRIPT has '#{pane_id}' nvim" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$PANE_SCRIPT pick nvim'" \
  "display-message -d 1500 'no nvim panes'"

# opencode run prompt picker (commands from run-commands.json)
bind -n M-c if-shell "$OPENCODE_SCRIPT has" \
  "display-popup -B -E -d '#{pane_current_path}' -w 90% -h 80% '$OPENCODE_SCRIPT pick'" \
  "display-message -d 1500 'no run commands'"
