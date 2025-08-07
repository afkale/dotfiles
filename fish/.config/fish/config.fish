# Only execute this file once per shell.
status is-login; and begin
    # Login shell initialisation
end

status is-interactive; and begin

end

# Set greeting to empty
set fish_greeting

set -gx PATH $HOME/.cargo/bin $PATH

# setup vi_key_bindings
fish_vi_key_bindings

set -Ux EDITOR nvim
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if status is-interactive
		atuin init fish | source
		carapace _carapace | source
		zoxide init fish | source
		starship init fish | source
end
