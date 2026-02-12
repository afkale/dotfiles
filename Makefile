PKGS_MANAGER := paru
PKGS_MANAGER_FLAGS := -Syu --noconfirm --needed

CORE_PKGS := git neovim stow kitty \
						 ttf-cascadia-code ttf-cascadia-code-nerd ttf-nerd-fonts-symbols ttf-jetbrains-mono ttf-font-awesome-5

TERMINAL_PKGS := $(CORE_PKGS) \
								 tmux lazygit ncdu btop fish bat carapace lsd \
								 fzf fd ripgrep zoxide the_silver_searcher universal-ctags \
								 lua-language-server bash-language-server vscode-langservers-extracted \
								 ruff pyright rust cargo

TERMINAL_CFG_DIRS := fish \
										 nvim \
										 kitty \
										 tmux \
										 lazygit

DESKTOP_PKGS := $(CORE_PKGS) \
								hyprland hyprpaper hyprlock hypridle hyprshot mako swayosd waybar wlogout \
								network-manager-applet pwvucontrol bitwarden brave-bin \
								dracula-icons-git bibata-cursor-theme-bin 

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
	@touch hypr/.config/hypr/pc.conf
	@sudo mkdir -p /usr/share/themes
	@[ -d $(GTK_THEME_DIR) ] && echo "Removing $(GTK_THEME_DIR) ..." && sudo rm -rfI $(GTK_THEME_DIR)
	@[ -d $(GTK_THEME_DIR) ] || sudo git clone $(GTK_THEME_REPO) $(GTK_THEME_DIR)

	@gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
	@gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
	@gsettings set org.gnome.desktop.interface icon-theme "Dracula"

terminal-scripts:
	@chsh -s /usr/bin/fish

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd nvim/.config/nvim && git checkout main

install-terminal: install-terminal-packages sync-submodules link-terminal-dotfiles terminal-scripts
install-desktop: install-desktop-packages desktop-scripts link-desktop-dotfiles

install: install-terminal install-desktop
