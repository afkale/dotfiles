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

# Snapshot the current layout (restore with sessions.sh after a reboot).
bind -n M-C-s run-shell "$SESSIONS_SCRIPT save"

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
