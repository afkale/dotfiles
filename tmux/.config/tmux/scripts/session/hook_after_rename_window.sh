#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/envs.sh"
source "$SCRIPT_DIR/helpers.sh"

main() {
  tmux_clean_session_panes > "$FZF_SESSION_HISTORY"
}
main
