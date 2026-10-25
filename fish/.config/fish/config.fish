# Only execute this file once per shell.
status is-login; and begin
  # Login shell initialisation
end
set fish_greeting


fish_vi_key_bindings

set -gx EDITOR nvim
set -gx FZF_DEFAULT_OPTS "--reverse --color=bg+:#313244,bg:,spinner:#F5E0DC,hl:#F38BA8 --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086,label:#CDD6F4"

if type -q pass-cli
  set -gx SSH_AUTH_SOCK "/home/afkale/.ssh/proton-pass-agent.sock"
end


if status is-interactive
  zoxide init fish | source
  fzf --fish | source
end

fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.local/opt/go/bin"
fish_add_path "$HOME/go/bin"
