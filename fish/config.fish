if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting
set -g fish_key_bindings fish_vi_key_bindings

set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
starship init fish | source
