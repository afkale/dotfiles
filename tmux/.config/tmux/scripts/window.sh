#!/usr/bin/env bash
# window.sh — fuzzy window navigator across every session (M-d).
#
#   window.sh list       "<window_id><TAB><label>", plain order, for fzf
#   window.sh pick       switch to the selected window
#
# Every window in every session is listed as "session: window", except windows
# in hidden sessions and the current window (no point navigating to where you
# already are).
#
# Hidden sessions ("_hidden*") are excluded everywhere.

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SELF%/*}
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

FIELDS="#{session_name}"$'\t'"#{window_index}"$'\t'"#{window_name}"$'\t'"#{window_id}"$'\t'"#{session_id}"$'\t'"#{?window_active,active,inactive}"

list() {
  local current_session current_window sn win_idx win_name win_id

  current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
  current_window=$(tmux display-message -p '#{window_index}' 2>/dev/null || true)

  # shellcheck disable=SC2034 # win_idx, sid, is_active captured from tmux format
  while IFS=$'\t' read -r sn win_idx win_name win_id sid is_active; do
    [ -n "$sn" ] || continue
    is_hidden_session "$sn" && continue

    # Skip the current window — you're already there, no point navigating to it.
    [ "$sn" = "$current_session" ] && [ "$win_idx" = "$current_window" ] && continue

    printf '%s\t%s\n' "$win_id" "  $sn: $win_name"
  done < <(tmux list-windows -a -F "$FIELDS" 2>/dev/null)
}

pick() {
  local entries selection win_id

  entries=$(list)
  if [ -z "$entries" ]; then
    message "no windows"
    return 0
  fi

  selection=$(
    printf '%s\n' "$entries" | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      "${FZF_STYLE[@]}" \
      --border-label='   windows ' \
      --header='enter: switch · ctrl-v: preview · ctrl-r: reload' \
      --preview 'tmux capture-pane -p -e -t {1} -S -200' \
      --preview-window='right,60%,border-left' \
      --bind 'ctrl-v:toggle-preview' \
      --bind "ctrl-r:reload($SELF list)" \
      --bind 'enter:become(echo {1})'
  )

  [ -n "$selection" ] || return 0
  win_id=$selection

  # Switch to the window. If it's in a different session, switch the client
  # to that session first.
  local current_sid target_sid
  current_sid=$(tmux display-message -p '#{session_id}' 2>/dev/null) || current_sid=""
  target_sid=$(tmux display-message -p -t "$win_id" '#{session_id}' 2>/dev/null) || return 0

  if [ "$target_sid" != "$current_sid" ]; then
    local client
    client=$(client_for_session "$(current_session_id)")
    if [ -n "$client" ]; then
      tmux switch-client -c "$client" -t "$target_sid" 2>/dev/null || true
    else
      tmux switch-client -t "$target_sid" 2>/dev/null || true
    fi
  fi

  tmux select-window -t "$win_id" 2>/dev/null || true
}

# Guard: only dispatch when executed directly, not sourced (for tests).
(return 0 2>/dev/null) && return 0

case "${1:-}" in
  list) list ;;
  pick) pick ;;
  *)
    printf 'usage: %s {list|pick}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
