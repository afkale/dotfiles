# Global (prefix-less) key bindings.

# ---------------------------------------------------------------------------
# Rename
# ---------------------------------------------------------------------------
bind -n M-r command-prompt "rename-window '%%'"
bind -n M-C-r command-prompt "rename-session '%%'"

# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------
# M-C-w creates a project session with the workmux sidebar (see session.sh).
# Two prompts: session name, then window name (default "code").
# %% in the second prompt is the first prompt's answer (session name).
bind -n M-C-w \
  command-prompt -p "session name:" \
    "command-prompt -I \"code\" -p \"first window name (enter for 'code'):\" \
      \"run-shell '$TMUX_SCRIPTS/session.sh create \"#{pane_current_path}\" \"%%\" \"%1\"'\""

# M-w creates a new window in the current session, prompting for its name.
bind -n M-w \
  new-window -c "#{pane_current_path}" \; \
  command-prompt "rename-window '%%'"

# M-C-d: convenience alias for M-w (you can drop this if M-w is enough).
bind -n M-C-d \
  new-window -c "#{pane_current_path}" \; \
  command-prompt "rename-window '%%'"

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------
# M-` (backtick) jumps to the last window (highest index) in the session.
bind -n M-\` last-window

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
bind -n M-v copy-mode
bind -n M-b set status

# ---------------------------------------------------------------------------
# Session recording (streamux)
# ---------------------------------------------------------------------------
bind -n M-a run-shell -b "$STREAMUX_SCRIPT start"
bind -n M-C-a run-shell -b "$STREAMUX_SCRIPT stop"

# ---------------------------------------------------------------------------
# Lock mode: only M-L keeps working until it is pressed again.
# ---------------------------------------------------------------------------
set -g @locked 0

bind -n M-L \
  set -g @locked 1 \; \
  set -g @logo " " \; \
  set prefix None \; \
  set key-table off

bind -T off M-L \
  set -g @locked 0 \; \
  set -g @logo " " \; \
  set -u prefix \; \
  set -u key-table

# ---------------------------------------------------------------------------
# Copy mode
# ---------------------------------------------------------------------------
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel \
  "wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || cat >/dev/null"
bind-key -T copy-mode-vi Escape send-keys -X cancel
