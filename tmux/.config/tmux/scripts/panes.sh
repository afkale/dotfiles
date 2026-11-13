#!/usr/bin/env bash
# panes.sh — fuzzy picker over every tmux pane (M-d).
#
#   panes.sh list   "<pane_id><TAB><label>", plain order, for fzf
#   panes.sh pick   switch to the selected pane
#
# Every pane in every session is listed, except agent-manager sessions (am_*)
# and popup sessions (_hidden*): agent panes are agent-manager's own list, and
# popups are transient. The current pane is omitted so Enter jumps back to
# where you came from.

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

FIELDS="#{pane_id}"$'\t'"#{session_name}"$'\t'"#{window_index}"$'\t'"#{pane_index}"$'\t'"#{window_name}"

# Shared look for the menu; the palette matches the status bar.
# shellcheck disable=SC2034 # used by the fzf call in pick()
FZF_STYLE=(
  --cycle
  --ansi
  --info=inline
  --border=rounded
  --color="fg:#908caa,bg:#191724,hl:#eb6f92,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92"
  --color="info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177"
  --color="header:#6e6a86,border:#403d52,label:#c4a7e7,selected-bg:#26233a"
)

is_skipped_session() {
  case "${1:-}" in
    am_* | _hidden*) return 0 ;;
    *) return 1 ;;
  esac
}

list() {
  local current_pane pane sn win_idx pane_idx win_name label

  current_pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)

  while IFS=$'\t' read -r pane sn win_idx pane_idx win_name; do
    [ -n "$pane" ] || continue
    is_skipped_session "$sn" && continue
    [ "$pane" = "$current_pane" ] && continue

    label="  $sn:$win_idx.$pane_idx  $win_name"
    printf '%s\t%s\n' "$pane" "$label"
  done < <(tmux list-panes -a -F "$FIELDS" 2>/dev/null)
}

focus_pane() {
  local pane="${1:-}" target_sid current_sid client

  [ -n "$pane" ] || return 0

  target_sid=$(tmux display-message -p -t "$pane" '#{session_id}' 2>/dev/null) || return 0
  current_sid=$(tmux display-message -p '#{session_id}' 2>/dev/null || true)

  if [ -n "$target_sid" ] && [ "$target_sid" != "$current_sid" ]; then
    client=$(tmux list-clients -F '#{client_name}' -t "$current_sid" 2>/dev/null | head -n 1)
    if [ -n "$client" ]; then
      tmux switch-client -c "$client" -t "$target_sid" 2>/dev/null || true
    else
      tmux switch-client -t "$target_sid" 2>/dev/null || true
    fi
  fi

  tmux select-window -t "$pane" 2>/dev/null || true
  tmux select-pane -t "$pane" 2>/dev/null || true
}

pick() {
  local entries selection

  entries=$(list)
  if [ -z "$entries" ]; then
    tmux display-message -d 1500 "no other panes"
    return 0
  fi

  selection=$(
    printf '%s\n' "$entries" | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      "${FZF_STYLE[@]}" \
      --border-label='  panes · all sessions ' \
      --header='enter: go · ctrl-v: preview · ctrl-r: reload' \
      --preview 'tmux capture-pane -p -e -t {1} -S -200' \
      --preview-window='right,60%,border-left' \
      --bind 'ctrl-v:toggle-preview' \
      --bind "ctrl-r:reload($SELF list)" \
      --bind 'enter:become(echo {1})'
  )

  [ -n "$selection" ] || return 0
  focus_pane "$selection"
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
