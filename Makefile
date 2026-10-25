# Packages stowed into ~/.config
CFG_DIRS := ai fish ghostty lazygit nvim tmux wallpapers

setup:
	@git submodule init
	@git submodule update --remote --recursive
	@git -C nvim/.config/nvim checkout main
	@chsh -s /usr/bin/fish

# `ai` holds the generic `ai run` menu; opencode is the provider package.
# Keep ~/.config/opencode a real directory so cli.json and service.json
# stay private instead of being folded into the repo.
link-dotfiles:
	@stow -t ~ $(CFG_DIRS)
	@stow --no-folding -t ~ opencode
