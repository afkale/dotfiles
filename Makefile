

CORE_PKGS = \
						git neovim stow wezterm

# Package list
PKGS = \
			 wezterm lazygit ncdu btop fish atuin bat carapace starship lsd \
			 fzf fd ripgrep zoxide the_silver_searcher universal-ctags \
			 lua-language-server bash-language-server vscode-langservers-extracted \
			 ruff pyright rust cargo \
			 ttf-cascadia-code ttf-nerd-fonts-symbols-mono ttf-jetbrains-mono

# App list
APPS = \
			 fish \
			 nvim \
			 starship \
			 wezterm \
			 lazygit

DESKTOP_PKGS = \
							 hyprland hyprpaper mako swayosd waybar wlogout \
							 network-manager-applet blueman pwvucontrol bitwarden brave-bin \
							 dracula-icons-git

DESKTOP_APPS = \
							 hypr \
							 mako \
							 wlogout \
							 swayosd \
							 waybar \
							 backgrounds

# Tasks
install-packages:
	@paru -Syu --noconfirm --needed $(CORE_PKGS) $(PKGS)

install-desktop-packages:
	@paru -Syu --noconfirm --needed $(CORE_PKGS) $(DESKTOP_PKGS)

link-dotfiles:
	@stow -t ~ $(APPS) 

link-desktop-dotfiles:
	@stow -t ~ $(DESKTOP_APPS) 

dektop-scripts:
	@scripts/setup_gtk_theme.sh

set-default-shell:
	@chsh -s $$(which fish)

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd nvim/.config/nvim && git checkout main

install: install-packages sync-submodules link-dotfiles set-default-shell
install-desktop: install-desktop-packages link-desktop-dotfiles dektop-scripts
