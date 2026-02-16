#!/usr/bin/env bash

tmux_get_panes() {
  format="${1:-#S:#I.#P - #W}"
  tmux list-panes -a -F "$format"
}

tmux_get_current_session_pane() {
  tmux display-message -p "#S:#I.#P - #W" 
}

tmux_get_last_session_pane() {
  if [ -e "$FZF_SESSION_HISTORY" ]; then
    tail -n2 "$FZF_SESSION_HISTORY" | head -n1
  fi
}

tmux_clean_session_panes() {
  [ -f "$FZF_SESSION_HISTORY" ] || return 0
  
  local temp_file
  temp_file=$(mktemp)
  
  if grep -f <(tmux_get_panes) "$FZF_SESSION_HISTORY" > "$temp_file" 2>/dev/null; then
    mv "$temp_file" "$FZF_SESSION_HISTORY"
  else
    rm "$temp_file"
  fi
}

tmux_save_current_pane() {
  tmux_get_current_session_pane | xargs >> "$FZF_SESSION_HISTORY"
}
