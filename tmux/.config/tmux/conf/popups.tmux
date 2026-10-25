# Popups. -E closes the popup when the command exits.

# Terminal in the current directory
bind -n M-1 popup -d '#{pane_current_path}' -E -w 90% -h 90%

# Lazygit
bind -n M-g popup -B -d '#{pane_current_path}' -E -w 100% -h 100% lazygit

# Btop
bind -n M-p popup -B -d '#{pane_current_path}' -E -w 100% -h 100% btop

# Daily `ai run` prompts (run-commands.json). Selection launches a background
# window in the dedicated ai-runs session; opencode is the provider for now.
bind -n M-c if-shell "$AI_RUN_SCRIPT has" \
  "display-popup -B -E -d '#{pane_current_path}' -w 75% -h 60% '$AI_RUN_SCRIPT pick'" \
  "display-message -d 2500 'ai commands: check ~/.config/ai/run-commands.json'"

# Pane pickers (MRU ordered). Only open the popup when there is something to
# show: a popup that opens and immediately closes flashes the whole screen.
bind -n M-d if-shell "$PANE_SCRIPT has '#{pane_id}'" \
  "display-popup -B -E -d '#{pane_current_path}' -w 100% -h 100% '$PANE_SCRIPT pick'" \
  "display-message -d 1500 'no other panes'"

# Same picker, limited to panes with the opencode provider running.
bind -n M-o if-shell "$PANE_SCRIPT has '#{pane_id}' opencode" \
  "display-popup -B -E -d '#{pane_current_path}' -w 100% -h 100% '$PANE_SCRIPT pick opencode'" \
  "display-message -d 1500 'no opencode provider panes'"

# Same picker, limited to panes with nvim running.
bind -n M-n if-shell "$PANE_SCRIPT has '#{pane_id}' nvim" \
  "display-popup -B -E -d '#{pane_current_path}' -w 100% -h 100% '$PANE_SCRIPT pick nvim'" \
  "display-message -d 1500 'no nvim panes'"
