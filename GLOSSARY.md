# Terminal workflow

The vocabulary of a single terminal setup built on herdr (which replaced tmux): how workspaces,
tabs and panes are organised, how movement between them works, where agents run, and how the
surrounding tools (nvim, lazygit, yazi, btop, opencode) are reached. One person's workflow, not a
library.

## Language

### Foundations

**Client**:
A terminal attached to the herdr server, viewing one workspace at a time.
_Avoid_: terminal, connection

**Server**:
The background herdr process that owns panes and process state and keeps them alive across
detach.
_Avoid_: daemon, backend

**Workspace**:
The top-level project container — one per repo, task, or investigation. A workspace owns tabs
and panes, and its sidebar state rolls up from the agents inside it. Replaces the tmux session.
_Avoid_: session, project, space

**Tab**:
A full-terminal layout inside a workspace, used to separate views such as agents, logs, server,
or review. Replaces the tmux window.
_Avoid_: window, pane

**Pane**:
A real terminal region inside a tab that runs one process. Every new tab starts with a single
pane; panes can be split right or down.
_Avoid_: split, frame

**Agent**:
A process herdr recognises inside a pane, classified as blocked, working, done, idle, or
unknown. Only agent panes contribute to workspace status.
_Avoid_: job, task, process

### Control

**Prefix**:
The keystroke that arms herdr's own bindings instead of passing keys to the running program.
Bound to `alt+space`, with `ctrl+space` as fallback, to preserve tmux muscle memory.
_Avoid_: leader, modifier

**Terminal mode**:
The default state: every key goes to the focused pane.
_Avoid_: insert mode, normal mode

**Navigate mode**:
The persistent workspace navigation surface. Movement keys (`h/j/k/l`, arrows) move between
workspaces and panes; `Esc` or `Ctrl+[` leaves it.
_Avoid_: workspace mode, focus mode

**Goto picker**:
The `prefix+g` / `alt+d` list of every agent and terminal, grouped by workspace. `/` searches;
`j/k` moves when not searching.
_Avoid_: window list, switcher

**Copy mode**:
`prefix+[` enters vi-style scrollback navigation and selection in the focused pane. `v` or Space
starts a selection, `y` or Enter copies, `q` or Esc leaves; `/` and `?` search. The pane keeps
running throughout.
_Avoid_: scrollback, edit mode

**Resize mode**:
`prefix+shift+r` then movement keys adjusts split sizes. The binding moves off `r` so `r` can
stay the config reload key.
_Avoid_: layout mode

### Surfaces

**Sidebar**:
Herdr's left-side agent panel, rolled up per workspace: live status, and jump targets for
agents. Toggled with `prefix+b` or `alt+s`.
_Avoid_: workmux sidebar (legacy), agent strip, agent list

**Tool popup**:
A full-size overlay running a single tool — a file manager (`alt+y`), a git client (`alt+g`), or
a process monitor (`alt+p`) — that closes back to the pane beneath it.
_Avoid_: float, floating window

**Keymap help**:
Herdr's built-in panel listing every active binding, including custom commands. Opened with
`prefix+?` or `alt+?`; `/` filters, Backspace edits, `ctrl+u` clears.
_Avoid_: cheatsheet (legacy)

**Herdr session**:
A named persistent server namespace (`herdr --session work`) with its own panes, sockets, and
persisted runtime state. A different axis from a workspace; the unqualified word "session" is
never used for this.
_Avoid_: session, profile

### Work objects

**Worktree**:
An isolated checkout of the current repository for one task, created by workmux.
_Avoid_: task branch, sandbox checkout

**Handle**:
The worktree directory name, used to address agents in workmux commands. For example,
`docs-update` in `~/worktrees/dotfiles/docs-update`.
_Avoid_: worktree name, branch alias

**Agent status**:
Herdr's per-agent state — blocked, working, done, idle, or unknown — shown on the agent row and
summarised on the workspace.
_Avoid_: workmux status (legacy)

### The IDE

**IDE tab**:
A tab that holds the coding cockpit: nvim as the editor, with tool popups available over it.
Tabs stay whole rather than being split, so each IDE tab is one full view.
_Avoid_: editor window, dev window

## Legacy (tmux)

Kept so the tmux configuration still reads coherently. Tmux remains installed as a fallback and
is no longer the primary multiplexer.

**Session (tmux)** → Workspace. **Window** → Tab. **Pane** and **Prefix** carry over; the prefix
key is now `alt+space`.

**Lock mode**, **Hidden session**, **Recording** (streamux), and **Isolated popup** (`M-1`) are
retired. Herdr has no lock mode, popups are native rather than nested tmux servers, and streamux
is unused.

**Window list** (`M-d`) → Goto picker. **Sidebar** (`M-s`, workmux) → herdr Sidebar. **Agent
jump** (`M-C-n`) and **Agent toggle** (`M-C-p`) → Goto picker and sidebar. **Cheatsheet**
(`M-?`) → Keymap help. **Tool popup** (`M-y`/`M-g`/`M-p`) → `alt+y`/`alt+g`/`alt+p`.
**Dashboard** (`M-n`) and **Resurrect** (`M-C-r`) remain workmux CLI features only; they are no
longer bound.
