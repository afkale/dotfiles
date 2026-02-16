#!/usr/bin/env bash

TMUX_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"

# FZF session history
export FZF_SESSION_HISTORY="${FZF_SESSION_HISTORY:-$HOME/.fzf_session_history}"

# Tmux scripts directories
export TMUX_SESSION_SCRIPTS="${TMUX_SCRIPTS:-$TMUX_CONFIG_DIR/scripts/session}"
