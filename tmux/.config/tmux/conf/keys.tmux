# Global (prefix-less) key bindings.

# ---------------------------------------------------------------------------
# Rename
# ---------------------------------------------------------------------------
bind -n M-r command-prompt "rename-window '%%'"
bind -n M-C-r command-prompt "rename-session '%%'"

# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------
# M-C-w creates a project session managed by workmux (see session.sh).
# Prompts for a session name. Workmux creates a session-mode worktree named
# after the base branch, so subsequent workmux commands know about this
# session. The sidebar (M-s) is the primary agent management surface.
bind -n M-C-w \
  command-prompt -p "session name:" \
    "run-shell '$TMUX_SCRIPTS/session.sh create \"#{pane_current_path}\" \"%%\"'"

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
# Workmux agent navigation
# ---------------------------------------------------------------------------
# M-C-n: jump to the agent that most recently finished or is waiting for input.
# Repeated presses cycle through all completed/waiting agents.
bind -n M-C-n run-shell "workmux last-done"

# M-C-p: toggle between the current agent and the last agent you visited.
bind -n M-C-p run-shell "workmux last-agent"

# M-C-r: dry-run of workmux resurrect — preview what worktrees would reopen
# after a crash. Run `workmux resurrect` at the shell to actually restore.
bind -n M-C-r run-shell "workmux resurrect --dry-run"

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
