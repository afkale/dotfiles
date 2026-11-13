# dotfiles

My personal dotfiles — tmux, fish, neovim, ghostty, lazygit, yazi and opencode
configs, plus wallpapers and helpers to set them up on a fresh machine.

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
| `tmux/` | tmux | Thin multiplexer (Session / Window / Pane), pane picker (`M-d`), minimal Rose Pine bar |
| `fish/` | fish | Fzf integration (fd, bat previews), zoxide, `abbr am` for agent-manager |
| `nvim/` | neovim (submodule) | Mini.pick for files/grep/help, lazygit integration, spell for markdown/gitcommit, cursor restore |
| `ghostty/` | ghostty | Launches tmux |
| `lazygit/` | lazygit | Custom keybindings and theme |
| `yazi/` | yazi | Manager settings and Rosé Pine theme |
| `wallpapers/` | — | Wallpaper images |
| `opencode/` | opencode | Agent CLI — agent-manager MCP, merge/rebase skills |
| `scripts/` | — | `deps.sh`, `doctor.sh`, `push.sh` |

Agent workflow lives in **agent-manager** (the `am` command), not in the
terminal multiplexer.

## Keybindings

Prefix = `alt+space` (layout verbs only: splits, zoom, close, copy mode,
reload). Everything else is a direct chord.

| Key | Action |
|-----|--------|
| `M-w` | New window (prompts for name) |
| `M-C-w` | New session (prompts for session then window name) |
| `M-d` | Pane picker fzf — every pane, every session, `am_*` filtered out |
| `M-n` / `M-p` | Next / previous window |
| `M-r` / `M-C-r` | Rename window / session |
| `M-y` | Yazi file manager (popup) |
| `M-g` | LazyGit (popup) |
| `M-v` | Copy mode (vi keys, clipboard pipe) |

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

Tools that Homebrew can't provide (`ghostty`, `opencode`, `agent-manager`) are
printed at the end with install hints.

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
├── tmux/                     # tmux config + scripts
└── nvim/                     # Git submodule
```
