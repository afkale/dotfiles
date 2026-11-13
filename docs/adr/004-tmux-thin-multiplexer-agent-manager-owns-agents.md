# ADR-004: tmux is the thin multiplexer; agent-manager owns agents

**Status**: Accepted (supersedes ADR-003)

**Date**: 2026-11-13

## Context

ADR-003 (2026-11-13) installed herdr as the primary multiplexer, removing tmux
entirely. The argument was that herdr is "native agent-aware" and covers the same
multiplexer ground as tmux.

In practice, herdr introduced regressions that the tmux workflow never had:

1. **Herdr config was untracked** — the ADR accepted this as a reversible gap, but
   the gap meant no history, no `make stow`, and manual backup on every tweak.
2. **Direct chords depended on the host** — `alt+letter` popups that worked in
   tmux (where the terminal just passes them through) became unreliable when
   herdr intercepted them itself. The "survive Ghostty and the window manager"
   constraint was identified as a cost but not effectively mitigated.
3. **No last-window jump** — herdr has `last_pane` but no "last tab", and the
   ADR left `M-\`` unbound rather than binding something subtly different.
4. **No status bar hide above one tab** — the tab row returned the moment a
   second tab existed, which is the common case.
5. **Plugin lock-in** — herdr's plugin system (`cloudmanic.herdr-plus.projects`,
   `herdr-agent-state.js`, herdr TUI sessions) created opencode dependencies
   that broke during herdr upgrades.
6. **`prefix+&` closes a tab in one keystroke** — herdr's confirmation covers
   workspace closes, not tab closes, so live agent panes could be destroyed
   accidentally.

Meanwhile, agent-manager fills the agent role that was herdr's primary selling
point: it creates its own tmux sessions, tracks agent status, and provides its
own TUI and MCP. The multiplexer itself does not need to be "agent-aware" — the
agent manager sits above it, not inside it.

## Decision

### 1. tmux is the only multiplexer

The full tmux configuration is restored in this repo at:

```
tmux/.config/tmux/tmux.conf      — single-file config (no conf/ modules)
tmux/.config/tmux/scripts/panes.sh  — fzf pane picker (M-d)
```

Herdr is removed entirely:
- `herdr/` — deleted
- `ghostty` launches `tmux`, not `herdr`
- `opencode/cli.json` — herdr plugin removed
- `opencode/tui.jsonc` — herdr TUI session removed
- `opencode/plugins/herdr-agent-state.js` — removed
- `opencode/skills/worktree/`, `opencode/skills/coordinator/` — removed
- `make stow` covers `tmux/` instead of `herdr/`

### 2. The keymap is deliberately small

| Key | Action |
| --- | --- |
| `M-w` | new window, prompts for name |
| `M-C-w` | new session, prompts for session then window name |
| `M-d` | fzf pane picker (all sessions, agent sessions excluded) |
| `M-n` / `M-p` | next / previous window |
| `M-r` / `M-C-r` | rename window / session |
| `M-y` / `M-g` | yazi / lazygit popups |
| `M-v` | copy mode |
| `prefix` | splits, zoom, close, copy mode, reload |

Everything agent is on the `am` alias (`abbr am agent-manager`), not on a
dedicated tmux key.

### 3. Agent-manager holds the agent workflow

- `am` opens the agent-manager TUI
- `agent-manager spawn` creates new agent sessions
- `M-d` explicitly filters `am_*` sessions out — the pane picker is for
  human-created windows only
- agent-manager provides its own MCP to opencode; the snippet is tracked in
  `opencode/.config/opencode/opencode.jsonc` as the `mcp.agent-manager` block.
  The agent-manager side of the MCP hook is tracked in
  `agent-manager/.config/agent-manager/hooks/mcp-opencode.json`.
- agent-manager's OpenCode TUI plugin (`track-conversation`) is tracked in
  `opencode/.config/opencode/plugins/agent-manager/tui.ts`.

### 4. Glossary is rewritten for tmux + agent-manager

`GLOSSARY.md` uses Session / Window / Pane, with Agent session defined as an
`am_*` tmux session managed by agent-manager. Herdr terms (Workspace, Tab,
Sidebar, Goto picker) are dropped entirely.

## Consequences

- `tmux/` — config and scripts tracked and stowable
- `ghostty/config` — `command = tmux`
- `packages/arch.txt`, `deps.sh`, `doctor.sh` — re-add `tmux`
- `packages/extra.txt` — add `agent-manager` install hint
- `GLOSSARY.md` — rewritten
- `MERGE.md` and `REBASE.md` skills — rewritten, workmux references removed
- ADR-003 — marked superseded; its config and plugins removed from the repo
