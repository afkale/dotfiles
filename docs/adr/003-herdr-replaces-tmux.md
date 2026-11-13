# ADR-003: Herdr replaces tmux as the terminal multiplexer

**Status**: Superseded by ADR-004

**Date**: 2026-11-13

## Context

The terminal workflow was built on tmux, with workmux providing sessions, worktrees, and an agent
sidebar (ADR-001, ADR-002). Herdr 0.9.5 is an agent-aware workspace manager that covers the same
multiplexer ground natively: workspaces, tabs, panes, copy mode, agent detection, and a sidebar.

The tmux map is deeply habitual: prefix `M-space`, one-key window movement, `M-g`/`M-y`/`M-p`
tool popups, and vi copy-mode keys. Moving to a tool with a different keymap would make the
switch cost real, but herdr's prefix model is tmux-shaped, so the habit can be carried over
rather than relearned.

Herdr also removes several bespoke pieces: no nested tmux for popups, no separate sidebar
daemon, and agents are first-class instead of being inferred by workmux.

## Decision

### 1. Herdr is primary; tmux is fully removed

Ghostty and daily use move to herdr. The tmux configuration has been removed entirely from the
dotfiles — no fallback is maintained. `~/.config/herdr/config.toml` is edited in place and is not
stowed into this repo for now; this is an accepted, reversible gap.

### 2. Prefix mirrors tmux

`prefix = ["alt+space", "ctrl+space"]` — `alt+space` first for muscle memory, `ctrl+space` as a
fallback for window managers or terminals that consume Alt+Space. Herdr accepts a prefix array,
so both arm the same prefix mode.

### 3. Scoped literal translation of the tmux prefix table

Tab-level actions keep tmux window meanings; workspace-level actions keep herdr defaults rather
than inventing new tmux meanings:

| Action | Key | tmux origin |
| --- | --- | --- |
| New tab | `prefix+c` | new-window |
| Previous / next tab | `prefix+p` / `prefix+n` | previous/next window |
| Jump to tab | `prefix+1..9` | select-window |
| Rename tab | `prefix+,` | rename-window |
| Close tab | `prefix+&` | kill-window |
| Close pane | `prefix+x` | kill-pane |
| Zoom | `prefix+z` | resize-pane -Z |
| Split right / down | `prefix+%` / `prefix+"` | split-window |
| Cycle panes | `prefix+o` | select-pane -t :.+ |
| Focus panes | `prefix+h/j/k/l` | select-pane |
| Copy mode | `prefix+[` | copy-mode |

Two collisions were resolved in favour of tmux habit: `prefix+r` reloads the config (as in the
tmux config), so resize moved to `prefix+shift+r`; and `prefix+o` cycles panes, so
`open_notification_target` is unbound.

### 4. A small set of direct chords survives

`alt+g` lazygit, `alt+y` yazi, and `alt+p` btop open tool popups; `alt+d` opens the Goto picker;
`alt+s` toggles the sidebar; `alt+?` opens keymap help. These are the non-readline keys from the
old `M-` map. Popups are herdr-native `[[keys.command]]` entries, not tmux clients.

Creation keeps its old direct keys as well: `alt+w` creates a tab (tmux `M-w`) and
`ctrl+alt+w` creates a workspace (tmux `M-C-w` new session), with `prefix+c` and
`prefix+shift+n` retained as the prefixed equivalents. Renaming mirrors the tmux map too:
`alt+r` renames the tab (`M-r` rename-window) and `ctrl+alt+r` renames the workspace
(`M-C-r` rename-session in tmux was shadowed by the resurrect binding, and that shadow is now
gone). The tab row hides while a workspace has one tab
(`ui.hide_tab_bar_when_single_tab`); herdr has no setting to hide it once a second tab
exists.

### 5. Retired tmux features are not emulated

Lock mode, streamux recordings, workmux (worktrees, dashboard, sidebar), the isolated `M-1`
popup, and the custom tmux copy-mode bindings are dropped. Herdr's copy mode already provides vi
selection and search, and the `M-1` script attaches a nested tmux server that cannot run inside a
herdr popup.

### 6. Glossary follows herdr

`GLOSSARY.md` is rewritten around Workspace / Tab / Pane / Agent, with tmux terms retained in a
Legacy section. "Herdr session" is kept distinct from "workspace" so the two axes are never
conflated.

## Rejected alternatives

### Keep tmux as primary and run herdr inside it

Rejected: the prefixes would nest (`alt+space` twice), and every agent feature would be filtered
through tmux's state instead of herdr's. It also defeats the purpose of replacing the
multiplexer.

### Keep herdr's default `ctrl+b` prefix

Rejected: it would split muscle memory between two machines and tools. `ctrl+b` also has a job
inside herdr copy mode (page up), which a `ctrl+b` prefix would take away.

### Port the entire `M-` direct-binding map

Rejected: `alt+b`, `alt+d`, `alt+a`, `alt+r`, and `alt+w` are readline/shell bindings that herdr
would intercept inside every pane, and plain `alt+letter` is the chord family most likely to be
eaten by the terminal or desktop environment. Only the popup/navigation subset is safe enough to
keep direct.

### Rewrite the `M-1` popup script for herdr

Rejected for now: the script is a nested tmux attach with its own socket, status bar, and
copy-mode table. Porting it is a rewrite, not a config change, and the Goto picker plus sidebar
cover most of its purpose. The script stays in the repo for later.

### Translate session-level tmux keys literally

Rejected: tmux `prefix+s`, `prefix+w`, and similar session operations were rarely used directly
and would collide with herdr's workspace picker and settings. Tab actions were the real muscle
memory, so only those were translated literally.

## Accepted costs

1. **No last-window jump** — herdr has `last_pane` but no "last tab". `M-\`` has no equivalent and
   `last_pane` is left unbound rather than bound to something subtly different.
2. **`prefix+&` closes a tab in one keystroke** — herdr's confirmation setting covers workspace
   closes, not tab closes, so a tab with live agents can be destroyed quickly.
3. **Direct chords depend on the host** — `alt+space` and the `alt+letter` popups must survive
   Ghostty and the window manager. `ctrl+space` is the fallback for the prefix only; popups fall
   back to being unavailable if Alt is consumed.
4. **Workmux integration is unverified** — workmux's dashboard, sidebar, and resurrect remain
   tmux-oriented until tested against herdr. Its CLI still works.
5. **Untracked herdr config** — the keymap is not in the dotfiles repo yet, so it has no history
   or `make stow` coverage. A future `herdr config reset-keys` would need a manual backup.
6. **Lost lock mode** — herdr has no read-only state, so accidental layout changes are prevented
   only by the prefix requirement.

## Consequences

- `~/.config/herdr/config.toml` — tmux-parity `[keys]` table and three popup commands
- `GLOSSARY.md` — rewritten herdr-first, with a Legacy (tmux) section
- `tmux/` — removed; no fallback maintained
- `ghostty/.config/ghostty/config.ghostty` — launch command not changed in this ADR; herdr is
  started explicitly for now
