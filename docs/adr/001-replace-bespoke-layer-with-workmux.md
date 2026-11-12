# ADR-001: Replace bespoke tmux task layer with workmux

**Status**: Accepted

**Date**: 2026-11-13

## Context

The dotfiles project originally managed tasks, worktrees, session state, and
agent navigation through a set of custom tmux scripts:

- `pane.sh` — MRU tracking, per-session and all-session pane pickers, last-pane
  jump
- `sessions.sh` — session picker, MRU tracking, layout snapshots and restore
- `worktree.sh` — worktree creation, picker, open-all, removal
- `ai.sh` — opencode run-prompt picker
- `hook-session-switch.sh` — combined client-session-changed hook
- `hooks.tmux` — MRU tracking hooks wired into every pane/window/session event

This was cohesive but duplicated functionality that workmux was built to
provide: worktree creation, agent lifecycle, and status display. Maintaining
bespoke pickers, MRU files, and snapshot state became technical debt — each new
feature required changes to multiple script files and their tests, and the state
files (`~/.local/state/tmux/*`) were opaque and fragile.

## Decision

Adopt workmux as the task/worktree/agent layer. workmux now owns:

- **Worktree creation** — `workmux add` replaces `worktree.sh new`
- **Agent status tracking** — `workmux status` replaces the bespoke MRU system
- **Dashboard display** — `workmux dashboard` replaces the pane/session pickers
  as the primary navigation surface
- **OpenCode integration** — `workmux setup --hooks` installs the status plugin
  for the tmux status bar

The remaining tmux scripts (`task.sh`, `window.sh`, `streamux.sh`, `popup.sh`,
`status.sh`) handle only the thin integration layer between tmux keybindings
and workmux or other external tools.

## Rejected alternatives

### Keep the script layer and maintain both

Maintaining both the bespoke scripts and workmux would have doubled the testing
and maintenance surface. The custom scripts would have atrophied while workmux
evolved.

### Session mode (workmux `--session`)

workmux supports a session mode where each agent gets its own tmux session
instead of a window. This was rejected because the existing window-per-worktree
model (all agents visible in one session's window list) maps naturally to the
`M-n` window navigator and keeps the workflow single-session.

### Sidebar UI for agent status

A persistent sidebar showing agent state was considered but rejected in favour
of the dashboard popup. The popup overlays the current terminal without
shrinking the editor pane, and it is available on demand (`M-d`) rather than
consuming screen real estate continuously.

### Bundle agent skills into the dotfiles

Pre-packaging agent skills (code review, TDD, etc.) directly into the dotfiles
was rejected because skills are a concern of opencode's skill system, not of
the terminal config. The dotfiles only configure the integration path.

## Accepted costs

1. **Tool dependency** — workmux must be installed via `cargo install workmux`
   (or Homebrew). This adds a non-trivial compilation step to `make deps` on
   machines without a Rust toolchain. Doctor.sh validates the installation.

2. **Handle-only window names** — workmux names windows by their handle
   (e.g. `docs-update`), not the full branch path. The full branch name is
   visible in the worktree's git status but not in the tmux window list. This
   trades precision for predictability.

3. **No snapshot/restore** — The old `sessions.sh save` and `sessions.sh
   restore` are gone. Sessions are ephemeral: after a reboot, create sessions
   as needed with `M-C-w`. workmux does not snapshot tmux session layouts.

4. **No MRU ordering in pickers** — workmux does not track recency by default
   for picker ordering. The `M-n` window list shows windows in tmux's natural
   session/window order rather than most-recently-used first.

## Consequences

- The dotfiles repo dropped ~1400 lines of retired script code across 6 files.
- Doctor.sh validates workmux installation, config linkage, and opencode
  plugin presence.
- Deps.sh installs workmux via cargo (or Homebrew), with a graceful warning
  when neither is available.
- Tests were pruned: the MRU and session picker test sections were removed.
- The tmux config is leaner (no hooks module, fewer `%hidden` variables) and
  delegates state management to an external tool with its own test surface.
