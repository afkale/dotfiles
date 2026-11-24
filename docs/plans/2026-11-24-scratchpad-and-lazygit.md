---
id: 2026-11-24-scratchpad-and-lazygit
title: tmux scratchpad window and lazygit custom commands
status: done            # draft | approved | denied | done
branch: main
ticket: ""
---

## Goal

Two independent improvements:

1. **tmux scratchpad window** — a persistent window for quick notes, toggled with `M-\``.
2. **lazygit custom commands** — keybindings for rebase-onto-main, force-push-with-lease, and amend.

## Design

### tmux scratchpad window

- Binding: `M-\`` toggles between the current window and a window named `scratch` in the
  current session. If no `scratch` window exists, create one running `$EDITOR` (or nvim) in
  the current pane's directory.
- Implementation in tmux.conf using a conditional bind:

```
bind -n M-` if -F '#{==:#{window_name},scratch}' 'last-window' 'select-window -t scratch 2>/dev/null || (new-window -n scratch -c "#{pane_current_path}" nvim +Scratchpad; select-window -t scratch)'
```

Actually, simpler: use a small script to handle the toggle logic cleanly.

- Create `tmux/.config/tmux/scripts/scratchpad.sh` that:
  - If a window named `scratch` exists in the current session, switch to it (or back to
    the previous window if already there).
  - Otherwise, create a new window named `scratch` running nvim, and switch to it.
- Bind `M-\`` to run the script.

### lazygit custom commands

Add to `lazygit/.config/lazygit/config.yml` under a `customCommands` key:

- **Rebase onto main**: `git rebase main` (or `origin/main`), bound to `r` in the commits view.
- **Force push with lease**: `git push --force-with-lease`, bound to `P` in the status view.
- **Amend last commit**: `git commit --amend --no-edit`, bound to `a` in the commits view.

Use lazygit's `customCommands` format with `key`, `command`, `context`, and `description`.

## Verification

- `bash -n` and `shellcheck -x` on the new script.
- tmux config loads.
- `make doctor` passes.
- lazygit config is valid YAML (parse with python or yq).

## Out of scope

- Scratchpad persistence across sessions (it's per-session).
- More lazygit commands beyond the three listed.
- Changes to nvim.
