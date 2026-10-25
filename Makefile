CFG_DIRS := fish ghostty lazygit nvim tmux wallpapers

setup:
	@git submodule init
	@git submodule update --remote --recursive
	@git -C nvim/.config/nvim checkout main
	@chsh -s /usr/bin/fish
	@${MAKE} -s link-dotfiles

link-dotfiles:
	@stow -t ~ $(CFG_DIRS)
	@stow --no-folding -t ~ opencode
