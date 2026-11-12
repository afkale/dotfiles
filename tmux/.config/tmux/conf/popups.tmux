# Popups. -E closes the popup when the command exits.

# Isolated popup. It has its own tmux socket, so only M-1 is bound there and
# the status bar is hidden (see scripts/popup.sh).
bind -n M-1 display-popup -d '#{pane_current_path}' -xC -yC -w 80% -h 75% -E "$POPUP_SCRIPT"

# Key cheatsheet: everything tmux knows, searchable.
bind -n M-? display-popup -B -E -w 90% -h 80% "tmux list-keys | fzf --reverse"

# Yazi — called directly; q quits via keymap.toml.
bind -n M-y display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  yazi ' yazi

# Lazygit — called directly; ESC quits by default.
bind -n M-g display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  lazygit ' lazygit

# Btop
bind -n M-p display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  btop ' btop

# Workmux dashboard: fullscreen popup, same shape as yazi/lazygit.
bind -n M-n display-popup -d '#{pane_current_path}' -E -w 100% -h 100% -T '  workmux dashboard ' workmux dashboard

# Window navigator: every window across every session.
bind -n M-d display-popup -B -E -w 90% -h 80% "$WINDOW_SCRIPT pick"

# Workmux sidebar: toggle the project-scoped agent sidebar in this session.
bind -n M-s run-shell "workmux sidebar -s"


