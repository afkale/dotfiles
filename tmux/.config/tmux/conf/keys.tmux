# Global (prefix-less) key bindings.

# ---------------------------------------------------------------------------
# Rename
# ---------------------------------------------------------------------------
bind -n M-r command-prompt "rename-window '%%'"
bind -n M-C-r command-prompt "rename-session '%%'"

# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------
bind -n M-C-w \
  new-session \; \
  command-prompt "rename-session '%%'" \; \
  command-prompt "rename-window '%%'"

bind -n M-w \
  new-window -c "#{pane_current_path}" \; \
  command-prompt "rename-window '%%'"

# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------
# Jump straight to the pane visited before this one (no picker).
bind -n M-` run-shell "$PANE_SCRIPT last"

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
bind -n M-v copy-mode
bind -n M-b set status

# ---------------------------------------------------------------------------
# Session recording (streamux)
# ---------------------------------------------------------------------------
bind -n M-s run-shell -b "$STREAMUX_SCRIPT start"
bind -n M-C-s run-shell -b "$STREAMUX_SCRIPT stop"

# ---------------------------------------------------------------------------
# Lock mode: only M-o keeps working until it is pressed again.
# ---------------------------------------------------------------------------
set -g @locked 0

bind -n M-o \
  set -g @locked 1 \; \
  set -g @logo " " \; \
  set prefix None \; \
  set key-table off

bind -T off M-o \
  set -g @locked 0 \; \
  set -g @logo " " \; \
  set -u prefix \; \
  set -u key-table

# ---------------------------------------------------------------------------
# Copy mode
# ---------------------------------------------------------------------------
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind-key -T copy-mode-vi Escape send-keys -X cancel
