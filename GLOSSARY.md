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
picker and scope, so popup shells never show up as places to jump to.
_Avoid_: background session, scratch session

### Navigation

**Window list**:
A searchable picker (`M-n`) showing every window across every session. The main way to jump
between tasks.
_Avoid_: window switcher, pane picker

**Dashboard**:
The workmux dashboard (`M-d`), a popup overlaying the current terminal that shows all active
agents and worktrees at a glance.
_Avoid_: sidebar, agent list

**Cheatsheet**:
A searchable popup of everything tmux currently has bound, read from the live server rather than
from a document.
_Avoid_: help, keybindings list

### The IDE

**IDE window**:
A window that holds the coding cockpit: nvim as the editor, with tool popups available over it.
Windows stay whole rather than being split, so each IDE window is one full view.
_Avoid_: editor window, dev window

**Tool popup**:
A full-size overlay running a single tool — a file manager (`M-y` yazi), a git client (`M-g`
lazygit), a process monitor (`M-p` btop), or the cheatsheet (`M-?`) — that closes back to the
pane beneath it.
_Avoid_: float, floating window

**Isolated popup**:
A popup (`M-1`) that runs its own tmux server with its own socket and a bare session, so the main
configuration's bindings and status bar do not leak into it.
_Avoid_: nested tmux, sandbox

### Work objects

**Worktree**:
An isolated checkout of the current repository for one task, created by workmux (`workmux add`).
The branch keeps the name you type; the directory and window name replace slashes with dashes.
_Avoid_: task branch, sandbox checkout

**Handle**:
The directory name of a worktree, used as the window name and as the address for workmux
commands. Derived from the branch name by replacing `/` with `-`.
_Avoid_: branch name, worktree name

**Agent status**:
An icon on the tmux status bar showing whether the worktree's opencode agent is busy, idle, or
absent, provided by `workmux status`.

**Recording**:
A per-session asciinema capture, started (`M-a`) and stopped (`M-C-a`) for the session it belongs
to and unaffected by other recordings on the machine.
_Avoid_: cast, stream
