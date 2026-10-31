set fish_greeting

fish_vi_key_bindings

set -gx EDITOR nvim
set -gx VISUAL $EDITOR
set -gx SUDO_EDITOR $EDITOR
set -gx GIT_EDITOR $EDITOR
set -gx PAGER less
set -gx LESS '-R'
set -gx FZF_DEFAULT_OPTS "--reverse --color=bg:#191724,bg+:#26233a,fg:#e0def4,fg+:#e0def4,hl:#eb6f92,hl+:#eb6f92,info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177,header:#eb6f92,border:#403d52,label:#c4a7e7,selected-bg:#403d52"

if type -q fd
  set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
end

if type -q bat
  set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}' --preview-window 'right,60%,border-left'"
end

if type -q bat; and type -q col
  set -gx MANPAGER 'sh -c "col -bx | bat -l man -p"'
end

if type -q pass-cli
  set -gx SSH_AUTH_SOCK "$HOME/.ssh/proton-pass-agent.sock"
end

if status is-interactive
  zoxide init fish | source
  fzf --fish | source
end

# Homebrew on Linux (installed by `make deps` on Debian/Ubuntu).
if test -x /home/linuxbrew/.linuxbrew/bin/brew
  fish_add_path /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin
else if test -x /opt/homebrew/bin/brew
  fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
else if test -x $HOME/.linuxbrew/bin/brew
  fish_add_path $HOME/.linuxbrew/bin $HOME/.linuxbrew/sbin
end

fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.local/opt/go/bin"
fish_add_path "$HOME/go/bin"
