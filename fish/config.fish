# setup vi_key_bindings
fish_vi_key_bindings

# Set greeting to empty
set fish_greeting
set -Ux EDITOR nvim
# Setup completion throught fish default configurations
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if status is-interactive

	# Load UV
	source $HOME/.local/bin/env.fish
	set PYENV_ROOT $HOME/.pyenv
	set -x PATH $PYENV_ROOT/shims $PYENV_ROOT/bin $PATH
	pyenv rehash

	# Commands to run in interactive sessions can go here
	atuin init fish | source
	# Autocompletion
	carapace _carapace | source
	# Fast moves
	zoxide init fish | source
	# Clean terminal
	starship init fish | source
end
