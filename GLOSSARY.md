# Terminal workflow

The vocabulary of a single terminal setup built on tmux: how sessions, windows and panes are
organised, how movement between them works, and how the surrounding tools (nvim, lazygit, yazi,
btop, opencode) are reached. One person's workflow, not a library.

## Language

### Foundations

**Client**:
A terminal attached to tmux, viewing one session at a time.
_Avoid_: terminal, connection

**Session**:
A named group of windows that a client attaches to.
_Avoid_: workspace, project

**Window**:
A container inside a session that fills the terminal and holds one or more panes. Windows are
indexed from 1 and renumbered when one closes.
_Avoid_: tab, workspace

**Pane**:
A region inside a window that runs one process. Every new window starts with a single pane.
_Avoid_: split, frame

**Prefix**:
The keystroke that arms tmux's own key bindings instead of passing keys to the running program.
Most day-to-day movement is bound without it.
_Avoid_: leader, modifier

**Bell flag**:
The mark on a pane that has rung its bell since it was last visited. A flagged pane appears in the
pane picker as plain gold text, with no icon.

**Lock mode**:
A state where every binding except the unlock key is inert, so a stray keystroke cannot rearrange
the layout. It is announced on the status bar.
_Avoid_: readonly mode

### Movement

**Picker**:
A searchable list overlaid on the current pane, where typing narrows the entries and Enter jumps to
the choice. Pickers share one look and one set of list keys.
_Avoid_: menu, switcher, fuzzy finder

**MRU**:
Recency order, newest first. Pane, session, worktree and run-prompt visits are recorded as they
happen; their pickers list in this order, and the pickers that have a "current" entry leave it out
so the first row is always the way back.
_Avoid_: history order, recent list

**Scope**:
The set of sessions a picker searches: the session it was opened from, or every session. Hidden
sessions are outside every scope.
_Avoid_: range, filter set

**Last pane**:
The pane visited before the current one. It is reached directly, with no picker, and is often the
editor you were just in.
_Avoid_: previous pane, alternate pane

**Filter**:
Narrowing a picker to panes by what is running in them, rather than by which session they belong
to.
_Avoid_: search, query

**Hidden session**:
A session whose name starts with an underscore, used to host popups. It is invisible to every
picker, scope and history file, so popup shells never show up as places to jump to.
_Avoid_: background session, scratch session

### Pickers

**Pane picker**:
The list of panes, either in the session it was opened from or across all sessions.
_Avoid_: window switcher

**Session picker**:
The list of sessions, most recently used first.

**Worktree picker**:
The list of task worktrees for the repository, with a preview of each one's status.

**Run-prompt picker**:
The list of named opencode prompts that can be run without a conversation.
_Avoid_: command menu

**Cheatsheet**:
A searchable list of everything tmux currently has bound, read from the live server rather than
from a document.

### The IDE

**IDE window**:
A window that holds the coding cockpit: nvim as the editor, with tool popups available over it.
Windows stay whole rather than being split, so each IDE window is one full view.
_Avoid_: editor window, dev window

**Tool popup**:
A full-size overlay running a single tool — a file manager, a git client, a process monitor — that
closes back to the pane beneath it.
_Avoid_: float, floating window

**Isolated popup**:
A popup that runs its own tmux server with its own socket and a bare session, so the main
configuration's bindings and status bar do not leak into it.
_Avoid_: nested tmux, sandbox

**Opencode pane**:
A pane whose foreground process is opencode. Panes matching it are what the opencode filter lists.
_Avoid_: AI window

**Run prompt**:
A named, reusable opencode instruction, run non-interactively in a popup to do one job — review
changes, summarise a diff — without opening a conversation.
_Avoid_: AI command, prompt snippet

### Work objects

**Worktree**:
An isolated checkout of the current repository for one task. The branch keeps the name you type;
the directory and window name replace slashes with dashes.
_Avoid_: task branch, sandbox checkout

**Task window**:
A window opened for a worktree, running opencode so the task starts in its own checkout.
_Avoid_: worktree window

**Snapshot**:
The recorded shape of the live sessions: their windows, panes and names. It is written as the
layout changes and when a client detaches.
_Avoid_: save file, layout file

**Restore**:
Recreating the sessions missing from a snapshot after a reboot. It never duplicates a session that
is already running.
_Avoid_: reload, recovery

**Recording**:
A per-session asciinema capture, started and stopped for the session it belongs to and unaffected
by other recordings on the machine.
_Avoid_: cast, stream
