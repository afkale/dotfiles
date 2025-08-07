# Package list
PKGS = \
	neovim git lazygit ncdu btop fish atuin bat carapace starship lsd stow \
	fzf fd ripgrep zoxide the_silver_searcher universal-ctags \
	lua-language-server bash-language-server vscode-langservers-extracted \
	ruff pyright rust cargo

APPS = \
	atuin \
	fish \
	nvim \
	starship \
	wezterm


# Tasks
install-packages:
	@yay -Syu --noconfirm --needed $(PKGS)

link-dotfiles:
	@stow -d ./ -t ~ $(APPS)

set-default-shell:
	@chsh -s $$(which fish)

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd nvim/.config/nvim && git checkout main

# Combined Tasks
install: install-packages sync-submodules link-dotfiles set-default-shell
update: update-packages
