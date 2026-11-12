# Popups. -E closes the popup when the command exits.

# Isolated popup. It has its own tmux socket, so only M-1 is bound there and
# the status bar is hidden (see scripts/popup.sh).
bind -n M-1 display-popup -d '#{pane_current_path}' -xC -yC -w 80% -h 75% -E "$POPUP_SCRIPT"

# Key cheatsheet: everything tmux knows, searchable.
bind -n M-? display-popup -B -E -w 90% -h 80% "tmux list-keys | fzf --reverse"

# Yazi
bind -n M-y display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  yazi ' yazi

# Lazygit
bind -n M-g display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  lazygit ' lazygit

# Btop
bind -n M-p display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  btop ' btop

# Window navigator: every window across every session.
bind -n M-n display-popup -B -E -w 90% -h 80% "$WINDOW_SCRIPT pick"

# Workmux dashboard: overview of all active agents and worktrees.
bind -n M-d display-popup -xC -yC -B -E -w 90% -h 80% "workmux dashboard"

# Task worktrees. M-W opens a prompt for a new task (create or reopen).
bind -n M-W display-popup -d '#{pane_current_path}' -E -w 60% -h 25% -T '  󰚩 task ' "$TASK_SCRIPT prompt"


