# dotfiles

My personal dotfiles — tmux, fish, neovim, ghostty, lazygit and opencode configs, plus helpers to set them up on a fresh machine.

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
| `tmux/` | tmux | Session picker (`M-s`), pane pickers (`M-d`, `M-o`, `M-n`), layout snapshots, isolated popup (`M-1`), asciinema recording (`M-a`/`M-C-a`), scratch shell (`M-t`) |
| `fish/` | fish | Fzf integration (fd, bat previews), zoxide, Homebrew PATH on Linux |
| `nvim/` | neovim (submodule) | Mini.pick for files/grep/help, lazygit integration, spell for markdown/gitcommit, cursor restore |
| `ghostty/` | ghostty | Minimal terminal config |
| `lazygit/` | lazygit | Custom keybindings and theme |
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
| `M-1` | Isolated popup shell |
| `M-t` | Scratch shell |
| `M-` `` | Last pane jump |
| `M-g` | LazyGit |
| `M-p` | Btop |
| `M-a` | Start asciinema recording |
| `M-C-a` | Stop recording |
| `M-C-s` | Save layout snapshot |
| `M-?` | Searchable keybinding cheatsheet |
| `M-b` | Toggle status bar |

Inside nvim:

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (including hidden paths) |
| `<leader>fg` | Live grep |
| `<leader>fh` | Help tags |
| `<leader>fr` | Resume last picker |
| `<leader>e`/`<leader>E` | Toggle file tree |
| `<leader>cc` | Toggle quickfix |

## Dependencies

**Arch Linux**: `make deps` installs everything with pacman.

**Debian / Ubuntu**: `make deps` installs:
1. Build dependencies with `apt-get`.
2. Homebrew if missing.
3. All config tools with `brew install`.

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
