# Package list
PKGS = \
	neovim git lazygit ncdu btop fish atuin bat carapace starship lsd stow \
	fzf fd ripgrep zoxide the_silver_searcher universal-ctags \
	lua-language-server bash-language-server vscode-langservers-extracted \
	ruff pyright rust cargo

# Tasks
install-packages:
	@yay -Syu --noconfirm --needed $(PKGS)

link-dotfiles:
	@stow -d ./ -t ~ *

set-default-shell:
	@chsh -s $$(which fish)

sync-submodules:
	@git submodule init
	@git submodule update --remote --recursive
	@cd dotfiles/nvim && git checkout main

update-packages:
	@yay -Syuu

# Combined Tasks
install: update-packages install-packages sync-submodules link-dotfiles set-default-shell
update: update-packages

