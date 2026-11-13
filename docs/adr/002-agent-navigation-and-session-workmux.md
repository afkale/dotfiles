# ADR-002: Agent navigation bindings and session-mode workmux integration

**Status**: Accepted

**Date**: 2026-11-13

## Context

After switching to workmux (ADR-001), the terminal workflow had several rough
edges:

1. **Window prefix noise** — The `window_prefix: "·"` setting prepended a middle
   dot to every worktree window name. The sidebar, dashboard, and status bar
   already identify worktrees unambiguously, so the dot was visual noise with no
   informational value.

2. **Manual session creation** — The `M-C-w` binding created sessions with
   `tmux new-session` and `tmux rename-*` commands, bypassing workmux entirely.
   Worktrees added later with `workmux add --parent-session` required the user
   to remember the exact session name.

3. **No quick agent navigation** — Jumping between agents required either the
   sidebar (`M-s` → navigate → Enter), the dashboard (`M-n` → navigate → Enter),
   or the window navigator (`M-d` → filter → Enter). There was no single-key
   "go to the agent that just finished" or "toggle between two agents."

4. **No crash recovery workflow** — After a tmux server restart, worktrees had
   to be reopened manually. Workmux's `resurrect` command existed but had no
   keybinding.

5. **Window navigator included the current window** — The fzf window navigator
   (`M-d`) listed every window including the one the user was already in, so
   selecting the first entry did nothing.

## Decision

### 1. Remove window prefix

Set `window_prefix: ""` in `~/.config/workmux/config.yaml`. Windows are named
solely by their worktree handle (e.g., `fix-login` instead of `·fix-login`).
The `Nerd Font` and `status_format` settings are unchanged.

### 2. Session creation delegates to workmux

`session.sh create` now runs `workmux add main --session <name> --base main --background`
instead of raw `tmux new-session`. This registers the session with workmux so
subsequent `workmux add --parent-session <name>` works without manual session
name tracking.

The `M-C-w` binding was simplified from a two-prompt chain (session name +
window name) to a single prompt (session name only). The window name defaults
to the base branch name, which workmux sets automatically.

### 3. Agent navigation bindings

Two workmux navigation commands get their own tmux keybindings:

| Binding | Command | Purpose |
|---------|---------|---------|
| `M-C-n` | `workmux last-done` | Jump to the most recent finished/waiting agent; cycle through all on repeat |
| `M-C-p` | `workmux last-agent` | Toggle between current and last-visited agent (like vim's `Ctrl+^`) |

These complement rather than replace the existing navigation surfaces
(sidebar, dashboard, window navigator). `M-C-n` is useful when an agent
finishes and you want to review its work. `M-C-p` is useful when context-
switching between two agents.

### 4. Crash recovery binding

`M-C-r` runs `workmux resurrect --dry-run` in a popup, previewing which
worktrees would be reopened. The actual restore requires running `workmux
resurrect` at the shell, keeping the destructive action deliberate.

### 5. Window navigator excludes current window

The `M-d` fzf picker (`window.sh list()`) now skips the current window via an
early `continue` when the session name and window index match the caller's.
This restores the behaviour from an earlier version of the navigator and
prevents the no-op of selecting the window you're already in.

## Rejected alternatives

### Keep window prefix for visual separation

The dot serves as a visual cue that a window is workmux-managed. Rejected
because the status bar already shows `#{@workmux_status}` (working/waiting/done
icons) for managed windows, so the dot adds no signal. Non-workmux windows
(plain shells, ad-hoc terminals) are rare in project sessions and obvious by
their name.

### Auto-start sidebar on session creation

Adding `workmux sidebar --session on` to `session.sh create` was considered.
Rejected because the sidebar is not always wanted — sometimes a clean session
with no persistent panes is preferred. The `M-s` toggle is sufficient.

### Automatic resurrect on tmux startup

Running `workmux resurrect` automatically when tmux starts was considered.
Rejected because crash recovery should be deliberate: the user should see what
would be restored before committing. The dry-run keybinding gives that preview.

## Accepted costs

1. **One additional prompt removed** — The `M-C-w` binding no longer asks for a
   window name. Users who want a custom initial window name must rename it
   manually with `M-r`.

2. **Workmux dependency in session creation** — Creating a project session now
   requires workmux to be installed and configured. If workmux is missing,
   `session.sh create` fails with a clear message rather than silently falling
   back to raw tmux.

3. **Window navigator shows fewer entries** — When the user has only one window
   in a session, `M-d` shows an empty list for that session. This is correct
   behaviour (nothing to navigate to) but may be momentarily confusing.

## Consequences

- `workmux/.config/workmux/config.yaml` — `window_prefix` changed from `"·"` to `""`
- `tmux/.config/tmux/conf/keys.tmux` — `M-C-w` binding simplified, `M-C-n`,
  `M-C-p`, `M-C-r` bindings added
- `tmux/.config/tmux/scripts/session.sh` — rewritten to delegate to workmux
- `tmux/.config/tmux/scripts/window.sh` — `list()` skips current window
- `tmux/.config/tmux/conf/popups.tmux` — comments updated for accuracy
- `GLOSSARY.md` — corrected `M-d`/`M-n` swap, added terms for agent jump,
  agent toggle, and resurrect
