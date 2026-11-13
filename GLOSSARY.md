# Terminal workflow

The vocabulary of a plain tmux setup with agent-manager alongside: how sessions,
windows and panes are arranged, how movement between them works, where agents
run, and how the surrounding tools (nvim, lazygit, yazi, opencode) are reached.
One person's workflow, not a library.

## Language

### Foundations

**Session**:
A named tmux server instance that holds windows and panes. The default session
is the main environment; agent-manager creates its own sessions (`am_*`) for
agents.
_Avoid_: workspace, project

**Window**:
A full-screen layout inside a session, used to separate views such as an editor,
logs, a server, or review. Windows are numbered and named.
_Avoid_: tab, view

**Pane**:
A terminal region inside a window that runs one process. Every new window starts
with a single pane; panes can be split.
_Avoid_: split, frame

**Agent session**:
A tmux session named `am_*`, created by agent-manager to run one agent CLI
(e.g. opencode). Not shown in `M-d` pane picker; managed through the `am`
command or agent-manager's own UI.
_Avoid_: worker, runner

### Control

**Prefix**:
`alt+space` arms tmux's own bindings instead of passing keys to the running
program. Used only for layout verbs: splits, zoom, close, copy mode, reload.
_Avoid_: leader

**Copy mode**:
`prefix+[` or `M-v` enters vi-style scrollback navigation and selection. `v`
starts a selection, `y` copies, `Escape` leaves; `/` and `?` search.
_Avoid_: scrollback mode

**Pane picker**:
`M-d` opens an fzf list of every pane in every session (agent sessions excluded),
with a preview of the pane contents on the right.

### Tools

**Tool popup**:
A full-size overlay running a single tool — yazi (`M-y`) or lazygit (`M-g`) —
that closes back to the pane beneath it.
_Avoid_: float, floating window

### The IDE

**nvim**:
The editor, launched in a tmux window. Tool popups are available over it.
