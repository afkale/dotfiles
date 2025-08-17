CORE_PKGS := git neovim stow wezterm

TERMINAL_PKGS := $(CORE_PKGS) \
								 wezterm lazygit ncdu btop fish atuin bat carapace starship lsd \
								 fzf fd ripgrep zoxide the_silver_searcher universal-ctags \
								 lua-language-server bash-language-server vscode-langservers-extracted \
								 ruff pyright rust cargo \
								 ttf-cascadia-code ttf-nerd-fonts-symbols-mono ttf-jetbrains-mono

TERMINAL_CFG_DIRS := fish \
										 nvim \
										 starship \
										 wezterm \
										 lazygit

DESKTOP_PKGS := $(CORE_PKGS) \
								hyprland hyprpaper mako swayosd waybar wlogout \
								network-manager-applet pwvucontrol bitwarden brave-bin \
								dracula-icons-git

DESKTOP_CFG_DIRS := hypr \
										mako \
										wlogout \
										swayosd \
										waybar \
										backgrounds

install-packages:
	@paru -Syu --noconfirm --needed  $(TERMINAL_PKGS)

install-desktop-packages:
	@paru -Syu --noconfirm --needed $(DESKTOP_PKGS)

link-terminal-dotfiles:
	@stow -t ~ $(TERMINAL_CFG_DIRS) 

link-desktop-dotfiles:
	@stow -t ~ $(DESKTOP_CFG_DIRS) 

dektop-scripts:
	# Create 
	@touch hypr/.config/hypr/pc.conf

	# Setup gtk-themes
	@sudo mkdir -p /usr/share/themes
	@sudo git clone https://github.com/afkale/dracula-gtk /usr/share/themes/Dracula
	@gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
	@gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
	@gsettings set org.gnome.desktop.interface icon-theme "Dracula"

set-default-shell:
	@chsh -s /usr/bin/fish

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd nvim/.config/nvim && git checkout main

install-terminal: install-packages sync-submodules link-dotfiles set-default-shell
install-desktop: install-desktop-packages dektop-scripts link-desktop-dotfiles
install: install-terminal install-desktop
