# dotfiles

My personal dotfiles — tmux, fish, neovim, ghostty, lazygit, yazi and opencode configs, plus wallpapers and helpers to set them up on a fresh machine.

## Quick start

```bash
# Clone with the nvim submodule.
git clone --recursive https://github.com/afkale/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Link everything into $HOME.
make setup

# Install tools (Arch or Debian/Ubuntu).
make deps

# Verify the setup.
make doctor
```

## Components

| Config | Tool | Notes |
|--------|------|-------|
| `tmux/` | tmux | Window navigator (`M-n`), workmux dashboard (`M-d`), task worktrees (`M-W`), isolated popup (`M-1`), asciinema recording (`M-a`/`M-C-a`) |
| `fish/` | fish | Fzf integration (fd, bat previews), zoxide, Homebrew PATH on Linux |
| `nvim/` | neovim (submodule) | Mini.pick for files/grep/help, lazygit integration, spell for markdown/gitcommit, cursor restore |
| `ghostty/` | ghostty | Minimal terminal config |
| `lazygit/` | lazygit | Custom keybindings and theme |
| `yazi/` | yazi | Manager settings and Rosé Pine theme |
| `wallpapers/` | — | Wallpaper images |
| `opencode/` | opencode | Run commands |
| `scripts/` | — | `deps.sh`, `doctor.sh`, `push.sh` |

## Keybindings

Inside tmux (`prefix` = `M-space`):

| Key | Action |
|-----|--------|
| `M-d` | Workmux dashboard |
| `M-n` | Window navigator (every window across every session) |
| `M-W` | New task worktree prompt |
| `M-1` | Isolated popup shell |
| `M-?` | Searchable keybinding cheatsheet |
| `M-y` | Yazi file manager |
| `M-g` | LazyGit |
| `M-p` | Btop monitor |
| `M-v` | Copy mode |
| `M-b` | Toggle status bar |
| `M-a` | Start asciinema recording |
| `M-C-a` | Stop recording |
| `M-L` | Lock mode (only `M-L` works until pressed again) |
| `M-r` | Rename window |
| `M-C-r` | Rename session |
| `M-C-w` | New session with first window |
| `M-C-d` | New window in current session |
| `prefix r` | Reload tmux config |

## Task worktrees

`M-W` prompts for a task name (a git branch name) and delegates to workmux.
workmux creates an isolated checkout at `~/worktrees/<repo>/<handle>`, opens a
tmux window for it, and launches the agent. If the handle already has a worktree,
it reopens the existing one.

New worktrees copy `.env`, `.env.local`, `.env.development.local` and `.envrc`
from the main checkout. Override the root with `WORKTREE_ROOT`.

## Dependencies

**Arch Linux**: `make deps` installs everything with pacman, including
`tree-sitter-cli` (used by `nvim-treesitter` to build parsers).

**Debian / Ubuntu**: `make deps` installs:
1. Build dependencies with `apt-get`.
2. Homebrew if missing.
3. All config tools with `brew install`, including `tree-sitter-cli`.

`tree-sitter-cli` comes from Homebrew on Debian/Ubuntu because the apt version
is too old for `nvim-treesitter` (0.20.8 on 24.04, 0.25.9 on 26.04; it needs
0.26.1 or newer).

Tools that Homebrew can't provide (`ghostty`, `opencode`) are printed at the end with install hints.

workmux is installed by `make deps` via cargo (or Homebrew when available) and
sets up its own opencode agent-status integration on first use.

## Layout

```
dotfiles/
├── Makefile                  # setup, deps, doctor, push targets
├── packages/                 # Package lists for each distro
│   ├── arch.txt
│   ├── debian.txt
│   └── extra.txt             # Manual install hints
├── scripts/
│   ├── deps.sh               # Distro-aware dependency installer
│   ├── doctor.sh             # Health checks (tools, links, syntax)
│   └── push.sh               # Push submodules, then parent
├── {tool}/.config/{tool}/…   # Stow-managed configs
└── nvim/                     # Git submodule
```
