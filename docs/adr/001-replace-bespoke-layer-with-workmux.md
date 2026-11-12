# ADR-001: Replace bespoke tmux task layer with workmux

**Status:** Accepted

## Context

The dotfiles project had developed a cohesive but increasingly costly task/agent layer
implemented in custom shell scripts. Five scripts (`pane.sh`, `sessions.sh`, `worktree.sh`,
`ai.sh`, `hook-session-switch.sh`) plus a hooks module handled:

- MRU tracking for panes, sessions, worktrees, and run prompts
- Session snapshotting and restoration across reboots
- Worktree creation, listing, pruning, and removal
- Run-prompt pickers for named opencode instructions
- A pane filter that detected opencode processes
- A side session (a "ai-runner" session) for background agent work

These were coherent and worked well, but they duplicated functionality that workmux provides
out of the box. As the project grew, maintaining the bespoke pickers, state files, and
session-restore logic became technical debt — each new feature required changes in the scripts,
the tmux keybindings, and the status bar formatting.

## Decision

Adopt workmux as the task/worktree/agent layer. Workmux owns:

- **Worktree creation** — `workmux add` creates an isolated checkout and opens opencode.
- **Agent status tracking** — `workmux status` provides busy/idle/absent icons for the status bar.
- **Dashboard display** — `workmux dashboard` shows all agents and worktrees in a popup.
- **Worktree removal** — `workmux remove` prunes the checkout and closes the window.

The tmux config delegates to workmux for these responsibilities instead of implementing them
in custom scripts.

## Rejected alternatives

1. **Keep the script layer and maintain both** — Adding workmux alongside the custom scripts
   would double the maintenance surface without clear benefit. The scripts were already at risk
   of diverging from workmux's behaviour.

2. **Session mode (`workmux --session`)** — Workmux supports a session mode where each agent
   gets its own tmux session. This would change the window-per-worktree model and break muscle
   memory for `M-n` window navigation. Keeping one session with multiple windows preserves
   the existing mental model.

3. **Sidebar UI for agent status** — Displaying agent status in a tmux sidebar (a vertical
   split) would consume screen real estate. The dashboard remains a popup that overlays the
   current terminal and disappears on a keypress.

4. **Bundle agent skills into the dotfiles** — Including opencode skills (review, planner,
   writer, etc.) in the dotfiles repo would couple skill updates to dotfile updates. Skills
   live in opencode's own skill library and are loaded by name.

## Accepted costs

1. **Tool dependency** — workmux must be installed (via `cargo install workmux` or `brew install
   workmux`). The dotfiles can't function as a pure-script setup anymore. `deps.sh` handles
   installation and `doctor.sh` validates presence.

2. **Handle-only window names** — Windows show the worktree handle (e.g. `feat-login`) instead
   of the full branch path or a custom label. The window name and directory name are the same
   string.

3. **No snapshot/restore** — Sessions are ephemeral. After a reboot, worktrees are created
   fresh with `workmux add`. There is no automatic restoration of the previous layout.

4. **No MRU ordering in pickers** — workmux doesn't track recency for the dashboard or
   individual pickers. The dashboard lists agents in creation order.

## Consequences

- The dotfiles repo dropped approximately 1400 lines of retired script code.
- `doctor.sh` validates workmux installation and configuration.
- `deps.sh` installs workmux via cargo on Arch and Debian/Ubuntu; `brew install workmux` on
  macOS.
- The tmux config is leaner — keybindings are declarative and delegate to workmux rather than
  orchestrating custom scripts.
- State management (which worktrees exist, which agents are running) is delegated to an
  external tool with its own test surface and maintenance.
