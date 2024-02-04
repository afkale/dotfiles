eval "$(starship init zsh)"

# Configuración del historial de zsh
HISTFILE=~/.tmux_history
HISTSIZE=10000
SAVEHIST=10000

## LS ALIASSES
alias ls="exa --icons"
alias la="exa --icons -a"
alias ll="exa --icons -la"
alias tree="exa --tree"

setopt inc_append_history

source /home/ale/.config/broot/launcher/bash/br

# ZSH plugins
if [[ -e $HOME/.config/zsh/plugins/init ]]; then
  source $HOME/.config/zsh/plugins/init
fi
