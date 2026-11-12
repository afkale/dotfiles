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

**Lock mode**:
A state where every binding except the unlock key is inert, so a stray keystroke cannot rearrange
the layout. It is announced on the status bar.
_Avoid_: readonly mode

**Hidden session**:
A session whose name starts with an underscore, used to host popups. It is invisible to every
picker, scope and history file, so popup shells never show up as places to jump to.
_Avoid_: background session, scratch session

### Navigation

**Window list**:
The `M-n` picker listing every window across every session. Windows in hidden sessions are
excluded. The current window is marked with a narrow arrow.
_Avoid_: window switcher, session list

**Dashboard**:
The `M-d` popup showing workmux's full overview of all active agents and worktrees.
Used for deeper inspection, diffing, and actions that need the full TUI.
_Avoid_: full view, TUI overview

**Sidebar**:
A persistent left-side pane in every window of a project session, scoped to that
session's agents only. It is the primary management surface for agent work:
showing live status, starting new worktrees, and jumping between agents.
Toggled on demand with `M-s`.
_Avoid_: sidebar popup, agent strip, agent list

**Cheatsheet**:
A searchable list of everything tmux currently has bound, read from the live server rather than
from a document. Opened with `M-?`.

### Tools

**Tool popup**:
A full-size overlay running a single tool — a file manager (`M-y`), a git client (`M-g`), a process
monitor (`M-p`), or the cheatsheet (`M-?`) — that closes back to the pane beneath it.
_Avoid_: float, floating window

**Isolated popup**:
A popup (`M-1`) that runs its own tmux server with its own socket and a bare session, so the main
configuration's bindings and status bar do not leak into it.
_Avoid_: nested tmux, sandbox

### Work objects

**Worktree**:
An isolated checkout of the current repository for one task, created by workmux.
Managed from the sidebar, not via a separate prompt popup. The branch keeps the
name you type; the directory and window name replace slashes with dashes.
_Avoid_: task branch, sandbox checkout

**Handle**:
The worktree directory name, used to address agents in workmux commands. For example,
`docs-update` in `~/worktrees/dotfiles/docs-update`.
_Avoid_: worktree name, branch alias

**Agent status**:
An icon shown in both the sidebar and status bar, reporting the state of a workmux
agent: idle, working, waiting for input, or done. Provided by the workmux sidebar
daemon and opencode integration.

### Session boundary

**Recording**:
A per-session asciinema capture, started (`M-a`) and stopped (`M-C-a`) for the session it belongs
to and unaffected by other recordings on the machine.
_Avoid_: cast, stream

### The IDE

**IDE window**:
A window that holds the coding cockpit: nvim as the editor, with tool popups available over it.
Windows stay whole rather than being split, so each IDE window is one full view.
_Avoid_: editor window, dev window
