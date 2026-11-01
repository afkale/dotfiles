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
| `tmux/` | tmux | Session picker (`M-s`), pane pickers (`M-d`, `M-o`, `M-n`), layout snapshots, isolated popup (`M-1`), asciinema recording (`M-a`/`M-C-a`) |
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
| `M-s` | Session picker |
| `M-d` | Pane picker |
| `M-o` | Opencode pane picker |
| `M-n` | Nvim pane picker |
| `M-c` | Opencode run-prompt picker |
| `M-1` | Isolated popup shell |
| ``M-` `` | Last pane jump |
| `M-g` | LazyGit |
| `M-p` | Btop |
| `M-y` | Yazi |
| `M-v` | Copy mode |
| `M-a` | Start asciinema recording |
| `M-C-a` | Stop recording |
| `M-C-s` | Save layout snapshot |
| `M-b` | Toggle status bar |
| `M-L` | Lock mode (only `M-L` works until pressed again) |
| `M-r` / `M-C-r` | Rename window / session |
| `M-w` / `M-C-w` | New window / session |
| `M-?` | Searchable keybinding cheatsheet |
| `prefix r` | Reload tmux config |

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

Layout snapshots are saved to `~/.local/state/tmux/sessions`. Run `sessions.sh restore` after a reboot to recreate them.
