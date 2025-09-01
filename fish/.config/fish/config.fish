# Only execute this file once per shell.
status is-login; and begin
    # Login shell initialisation
end

status is-interactive; and begin

end

# Set greeting to empty
set fish_greeting

set -gx PATH $HOME/.cargo/bin $PATH

fish_vi_key_bindings

set -Ux EDITOR nvim

if status is-interactive
		atuin init fish | source
		zoxide init fish | source
end
