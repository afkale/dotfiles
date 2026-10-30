set fish_greeting

fish_vi_key_bindings

set -gx EDITOR nvim
set -gx VISUAL $EDITOR
set -gx PAGER less
set -gx FZF_DEFAULT_OPTS "--reverse --color=bg:#191724,bg+:#26233a,fg:#e0def4,fg+:#e0def4,hl:#eb6f92,hl+:#eb6f92,info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177,header:#eb6f92,border:#403d52,label:#c4a7e7,selected-bg:#403d52"

if type -q pass-cli
  set -gx SSH_AUTH_SOCK "$HOME/.ssh/proton-pass-agent.sock"
end

if status is-interactive
  zoxide init fish | source
  fzf --fish | source
end

fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.local/opt/go/bin"
fish_add_path "$HOME/go/bin"
