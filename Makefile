PKGS_MANAGER := paru
PKGS_MANAGER_FLAGS := -Syu --noconfirm --needed

CORE_PKGS := git neovim stow kitty \
						 ttf-cascadia-code ttf-cascadia-code-nerd ttf-nerd-fonts-symbols ttf-jetbrains-mono ttf-font-awesome-5

TERMINAL_PKGS := $(CORE_PKGS) \
								 tmux lazygit ncdu btop fish bat carapace lsd \
								 fzf fd ripgrep zoxide universal-ctags lua-language-server \
								 bash-language-server vscode-langservers-extracted \
								 ruff pyright rust cargo

TERMINAL_CFG_DIRS := fish nvim kitty tmux lazygit

DESKTOP_PKGS := $(CORE_PKGS) mako swayosd waybar wlogout cava bitwarden brave-bin
								

DESKTOP_CFG_DIRS := hypr \
										mako \
										wlogout \
										swayosd \
										waybar \
										assets

GTK_THEME_DIR := /usr/share/themes/Dracula/
GTK_THEME_REPO := https://github.com/afkale/dracula-gtk


install-terminal-packages:
	@$(PKGS_MANAGER) $(PKGS_MANAGER_FLAGS) $(TERMINAL_PKGS)


install-desktop-packages:
	@$(PKGS_MANAGER) $(PKGS_MANAGER_FLAGS) $(DESKTOP_PKGS)

link-terminal-dotfiles:
	@stow -t ~ $(TERMINAL_CFG_DIRS) 

link-desktop-dotfiles:
	@stow -t ~ $(DESKTOP_CFG_DIRS) 

desktop-scripts:
	curl -fsSL https://install.danklinux.com | sh

terminal-scripts:
	@chsh -s /usr/bin/fish
	@fish -c 'set -Ux FZF_DEFAULT_OPTS "--reverse --color=bg+:#313244,bg:,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4"'

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd nvim/.config/nvim && git checkout main

install-terminal: install-terminal-packages sync-submodules link-terminal-dotfiles terminal-scripts
install-desktop: install-desktop-packages link-desktop-dotfiles desktop-scripts

install: install-terminal install-desktop
