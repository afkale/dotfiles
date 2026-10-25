#!/usr/bin/env bash
# pane.sh — MRU tracking, "last pane" jump and the fuzzy pane picker (M-d).
#
#   pane.sh save [PANE_ID]       remember a pane as the most recently used
#   pane.sh prune                forget panes that no longer exist
#   pane.sh list [FILTER]        MRU-ordered "<pane_id><TAB><label>" for fzf
#   pane.sh last                 jump to the previous pane (M-`)
#   pane.sh pick [FILTER]        fzf pane picker (M-d, M-o for opencode panes)
#   pane.sh has [PANE] [FILTER]  true when the picker would have entries
#   pane.sh open-window PANE_ID  open that pane's directory in a new window
#   pane.sh close-session PANE_ID    close that pane's session (pane if current)
#
# History is a plain list of pane ids ("%12"), newest first. Pane ids are
# stable across renames and contain no spaces, so names can never break it.

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
HISTORY="${FZF_SESSION_HISTORY:-$HOME/.fzf_session_history}"
LIMIT="${FZF_SESSION_HISTORY_LIMIT:-100}"

# Private per-user scratch dir for the lock and atomic-write temp files.
# XDG_RUNTIME_DIR is already user-private; /tmp is only a fallback.
runtime_dir() {
  local root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
  local dir="$root/tmux-pane-$(id -u)"

  if mkdir -p "$dir" 2>/dev/null && [ -O "$dir" ]; then
    chmod 700 "$dir" 2>/dev/null || true
    printf '%s\n' "$dir"
  else
    mktemp -d "$root/tmux-pane-$(id -u).XXXXXX" 2>/dev/null || printf '%s\n' "$root"
  fi
}

RUNTIME_DIR=$(runtime_dir)
LOCK="$RUNTIME_DIR/lock"

# field 1 = pane id, field 2 = human label, field 3 = window bell flag
FIELDS="#{pane_id}"$'\t'"#{session_name}:#{window_index}.#{pane_index} - #{window_name}"$'\t'"#{window_bell_flag}"

current_pane() {
  # Hooks and popups know their pane through TMUX_PANE; fall back to tmux.
  if [ -n "${TMUX_PANE:-}" ]; then
    printf '%s\n' "$TMUX_PANE"
  else
    tmux display-message -p '#{pane_id}' 2>/dev/null
  fi
}

# Client attached to a given session (needed when several terminals are open).
client_for_session() {
  tmux list-clients -F '#{session_id}'$'\t''#{client_name}' 2>/dev/null |
    awk -F'\t' -v session="${1:-}" '$1 == session { print $2; exit }'
}

# Serialize writers: several hooks can fire for a single movement.
lock() {
  command -v flock >/dev/null 2>&1 || return 0
  exec 9>>"$LOCK"
  flock -w 1 9 2>/dev/null || true
}

save() {
  local pane="${1:-}"
  [ -n "$pane" ] || pane=$(current_pane)
  [ -n "$pane" ] || return 0

  mkdir -p "$(dirname "$HISTORY")" 2>/dev/null || true
  lock

  local tmp
  tmp=$(mktemp "$RUNTIME_DIR/history.XXXXXX") || return 0
  {
    printf '%s\n' "$pane"
    [ -f "$HISTORY" ] && cat "$HISTORY"
  } | awk -v limit="$LIMIT" \
        'length($0) && !seen[$0]++ && count++ < limit' >"$tmp"
  mv -f "$tmp" "$HISTORY"
}

prune() {
  [ -s "$HISTORY" ] || return 0

  mkdir -p "$(dirname "$HISTORY")" 2>/dev/null || true
  lock

  local tmp
  tmp=$(mktemp "$RUNTIME_DIR/history.XXXXXX") || return 0
  grep -Fxf <(tmux list-panes -a -F '#{pane_id}' 2>/dev/null) \
    "$HISTORY" >"$tmp" 2>/dev/null
  mv -f "$tmp" "$HISTORY"
}

# Pane ids whose foreground command or title matches $1 (case-insensitive).
matching_ids() {
  tmux list-panes -a -F "#{pane_id}"$'\t'"#{pane_current_command}"$'\t'"#{pane_title}" 2>/dev/null |
    awk -F'\t' -v pat="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" \
      'tolower($2) ~ pat || tolower($3) ~ pat { print $1 }'
}

# Notified rows are drawn in rose-pine gold with a bell (fzf --ansi).
NOTIFY_COLOR=$'\033[38;2;246;193;119m'
RESET_COLOR=$'\033[0m'

print_entry() {
  local mark="  " notify="${4:-0}" color="" reset=""
  [ "${3:-0}" = 1 ] && mark="↩ "
  if [ "$notify" = 1 ]; then
    color=$NOTIFY_COLOR
    reset=$RESET_COLOR
    mark="$mark "
  fi
  printf '%s\t%s%s%s%s\n' "$1" "$color" "$mark" "$2" "$reset"
}

list() {
  local filter="${1:-}" current="" pane label bell first=1
  declare -A label_of=() listed=() allowed=() notified=()
  local order=()

  current=$(current_pane)

  if [ -n "$filter" ]; then
    while IFS= read -r pane; do
      [ -n "$pane" ] && allowed[$pane]=1
    done < <(matching_ids "$filter")
  fi

  while IFS=$'\t' read -r pane label bell; do
    [ -n "$pane" ] || continue
    [ -n "$filter" ] && [ -z "${allowed[$pane]+x}" ] && continue
    label_of[$pane]=$label
    [ "${bell:-0}" = 1 ] && notified[$pane]=1
    order+=("$pane")
  done < <(tmux list-panes -a -F "$FIELDS" 2>/dev/null)

  # 1. MRU: the pane visited before the current one comes first.
  if [ -f "$HISTORY" ]; then
    while IFS= read -r pane; do
      [ -n "$pane" ] || continue
      [ "$pane" = "$current" ] && continue
      [ -n "${label_of[$pane]+x}" ] || continue
      [ -n "${listed[$pane]+x}" ] && continue
      print_entry "$pane" "${label_of[$pane]}" "$first" "${notified[$pane]:-0}"
      listed[$pane]=1
      first=0
    done <"$HISTORY"
  fi

  # 2. Never visited yet: plain tmux order.
  for pane in "${order[@]}"; do
    [ "$pane" = "$current" ] && continue
    [ -n "${listed[$pane]+x}" ] && continue
    print_entry "$pane" "${label_of[$pane]}" 0 "${notified[$pane]:-0}"
  done
}

pane_exists() {
  [ -n "${1:-}" ] && tmux display-message -p -t "$1" '#{pane_id}' >/dev/null 2>&1
}

focus_pane() {
  local pane="${1:-}" session
  [ -n "$pane" ] || return 1
  session=$(tmux display-message -p -t "$pane" '#{session_id}' 2>/dev/null) || return 1
  [ -n "$session" ] || return 1

  local client
  client=$(client_for_session "$(tmux display-message -p '#{session_id}' 2>/dev/null)")
  if [ -n "$client" ]; then
    tmux switch-client -c "$client" -t "$session" 2>/dev/null || true
  else
    tmux switch-client -t "$session" 2>/dev/null || true
  fi
  tmux select-window -t "$pane" || return 1
  tmux select-pane -t "$pane" || return 1

  save "$pane"
}

last() {
  local current pane
  current=$(current_pane)

  if [ -f "$HISTORY" ]; then
    while IFS= read -r pane; do
      [ -n "$pane" ] || continue
      [ "$pane" = "$current" ] && continue
      pane_exists "$pane" || continue
      focus_pane "$pane" && return 0
    done <"$HISTORY"
  fi

  # No usable history: fall back to tmux's own last-pane.
  tmux last-pane 2>/dev/null || true
}

# True when there is at least one other pane to show. The key bindings use
# this before opening a popup, so an empty picker never flashes the screen.
has() {
  local pane="${1:-}" filter="${2:-}" out

  if [ -n "$pane" ]; then
    out=$(TMUX_PANE="$pane" list "$filter")
  else
    out=$(list "$filter")
  fi

  [ -n "$out" ]
}

pick() {
  touch "$HISTORY"

  local filter="${1:-}" list_cmd="$SELF list" label=" panes "
  if [ -n "$filter" ]; then
    list_cmd="$SELF list $filter"
    case "$filter" in
      opencode) label=" 󰚩 opencode " ;;
      nvim) label="  nvim " ;;
      *)        label=" $filter " ;;
    esac
  fi

  if [ -n "$filter" ] && [ -z "$(list "$filter")" ]; then
    tmux display-message -d 1500 "no $filter panes"
    return 0
  fi

  local selection
  selection=$(
    list "$filter" | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      --cycle \
      --info=inline \
      --ansi \
      --border=rounded \
      --border-label="$label" \
      --color='fg:#908caa,bg:#191724,hl:#eb6f92,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92' \
      --color='info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177' \
      --color='header:#6e6a86,border:#403d52,label:#c4a7e7,selected-bg:#26233a' \
      --header='enter: go · Ctrl-x: kill pane · Ctrl-d: close session · Ctrl-o: new window · Ctrl-r: reload' \
      --preview 'tmux capture-pane -p -e -t {1} -S -200' \
      --preview-window='right,60%,border-left' \
      --bind "ctrl-x:execute-silent(tmux kill-pane -t {1})+reload($list_cmd)" \
      --bind "ctrl-d:execute-silent($SELF close-session {1})+reload($list_cmd)" \
      --bind "ctrl-o:execute-silent($SELF open-window {1})+abort" \
      --bind "ctrl-r:reload($list_cmd)" \
      --bind 'enter:become(echo {1})'
  )

  [ -n "$selection" ] || return 0
  focus_pane "$selection"
}

open_window() {
  local pane="${1:-}" dir
  [ -n "$pane" ] || return 0
  dir=$(tmux display-message -p -t "$pane" '#{pane_current_path}' 2>/dev/null) || return 0
  tmux new-window -c "${dir:-$HOME}"
}

close_session() {
  local pane="${1:-}" target current
  [ -n "$pane" ] || return 0

  target=$(tmux display-message -p -t "$pane" '#{session_id}' 2>/dev/null) || return 0
  current=$(tmux display-message -p '#{session_id}' 2>/dev/null) || current=""

  if [ -n "$target" ] && [ "$target" != "$current" ]; then
    tmux kill-session -t "$target"
  else
    # Never kill the session we are sitting in: close that pane instead.
    tmux kill-pane -t "$pane"
  fi
}

case "${1:-}" in
  save) shift; save "${1:-}" ;;
  prune) prune ;;
  list) shift; list "${1:-}" ;;
  last) last ;;
  pick) shift; pick "${1:-}" ;;
  has) shift; has "${1:-}" "${2:-}" ;;
  open-window) shift; open_window "${1:-}" ;;
  close-session) shift; close_session "${1:-}" ;;
  *)
    printf 'usage: %s {save [pane_id]|prune|list [filter]|last|pick [filter]|has [pane] [filter]|open-window <pane_id>|close-session <pane_id>}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
