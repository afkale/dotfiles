# Package list
PKGS = \
			 wezterm neovim git lazygit ncdu btop fish atuin bat carapace starship lsd stow \
			 fzf fd ripgrep zoxide the_silver_searcher universal-ctags \
			 lua-language-server bash-language-server vscode-langservers-extracted \
			 ruff pyright rust cargo \
			 ttf-cascadia-code ttf-nerd-fonts-symbols-mono ttf-jetbrains-mono

# App list
APPS = \
			 atuin \
			 fish \
			 nvim \
			 starship \
			 wezterm

DESKTOP_PKGS = \
							 sway mako swayosd waybar \
							 nm-applet pwvucontrol bitwarden \
							 papirus-icon-theme-git 

DESKTOP_APPS = \
							 sway \
							 sway-contrib \
							 mako \
							 swayosd \
							 waybar

# Tasks
install-packages:
	@yay -Syu --noconfirm --needed $(PKGS)

install-desktop-packages:
	@yay -Syu --noconfirm --needed $(DESKTOP_PKGS)

link-dotfiles:
	@stow -d ./ -t ~ $(APPS)

link-desktop-dotfiles:
	@stow -d ./ -t ~ $(DESKTOP_APPS)

set-default-shell:
	@chsh -s $$(which fish)

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd nvim/.config/nvim && git checkout main

install: install-packages sync-submodules link-dotfiles set-default-shell
install-desktop: install-desktop-packages link-desktop-dotfiles
