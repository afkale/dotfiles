#!/usr/bin/env bash
# shellcheck shell=bash
# pane.sh — MRU tracking, "last pane" jump and the fuzzy pane picker (M-d).
#
#   pane.sh save [PANE_ID]       remember a pane as the most recently used
#   pane.sh prune                forget panes that no longer exist
#   pane.sh list [SCOPE] [FILTER]   MRU-ordered "<pane_id><TAB><label>" for fzf
#   pane.sh last                    jump to the previous pane (M-`)
#   pane.sh pick [SCOPE] [FILTER]   fzf pane picker: M-d current, M-f all,
#                                   M-o/M-n global filters
#   pane.sh has [SCOPE] [FILTER]    true when the picker would have entries
#   pane.sh open-window PANE_ID     open that pane's directory in a new window
#   pane.sh close-session PANE_ID   close that pane's session (pane if current)
#
# SCOPE is "current" (default) or "all". The current scope follows the pane
# that opened the picker, so it still works from popups.
#
# History is a plain list of pane ids ("%12"), newest first. Pane ids are
# stable across renames and contain no spaces, so names can never break it.
# Panes in sessions whose name starts with "_hidden" (such as the M-1
# "_hidden_popup") are ignored everywhere.

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
HISTORY="${FZF_SESSION_HISTORY:-$STATE_DIR/panes}"
LIMIT="${FZF_SESSION_HISTORY_LIMIT:-100}"

# Private per-user scratch dir for atomic-write temp files used by prune().
# XDG_RUNTIME_DIR is already user-private; /tmp is only a fallback.
runtime_dir() {
  local root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
  local dir
  dir="$root/tmux-pane-$(id -u)"

  if mkdir -p "$dir" 2>/dev/null && [ -O "$dir" ]; then
    chmod 700 "$dir" 2>/dev/null || true
    printf '%s\n' "$dir"
  else
    mktemp -d "$root/tmux-pane-$(id -u).XXXXXX" 2>/dev/null || printf '%s\n' "$root"
  fi
}

RUNTIME_DIR=$(runtime_dir)
LOCK="$RUNTIME_DIR/lock"

# field 1 = pane id, field 2 = human label, field 3 = window bell flag,
# field 4 = session name (used to hide "_hidden*" sessions), field 5 = session id
FIELDS="#{pane_id}"$'\t'"#{session_name}:#{window_index}.#{pane_index} - #{window_name}"$'\t'"#{window_bell_flag}"$'\t'"#{session_name}"$'\t'"#{session_id}"

# Sessions used for popups start with "_hidden" and stay out of pane searches.
is_hidden_pane() {
  local session
  [ -n "${1:-}" ] || return 1
  session=$(tmux display-message -p -t "$1" '#{session_name}' 2>/dev/null) || return 1
  is_hidden_session "$session"
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

  is_hidden_pane "$pane" && return 0

  mru_push "$HISTORY" "$pane" "$LIMIT"
}

prune() {
  [ -s "$HISTORY" ] || return 0

  local panes tmp
  panes=$(tmux list-panes -a -F "#{pane_id}"$'\t'"#{session_name}" 2>/dev/null) || return 0
  [ -n "$panes" ] || return 0

  mkdir -p "$(dirname "$HISTORY")" 2>/dev/null || true
  lock

  tmp=$(mktemp "$RUNTIME_DIR/history.XXXXXX") || return 0
  printf '%s\n' "$panes" |
    awk -F'\t' '$2 !~ /^_hidden/ { print $1 }' |
    grep -Fxf - "$HISTORY" >"$tmp" 2>/dev/null
  mv -f "$tmp" "$HISTORY"
}

# Pane ids whose foreground command or title contains $1 (case-insensitive).
matching_ids() {
  tmux list-panes -a -F "#{pane_id}"$'\t'"#{pane_current_command}"$'\t'"#{pane_title}" 2>/dev/null |
    awk -F'\t' -v pat="$1" '
      BEGIN { pat = tolower(pat) }
      index(tolower($2), pat) || index(tolower($3), pat) { print $1 }
    '
}

# Notified rows are plain gold text: no bell, no marker, no extra icon.
# RESET_COLOR and NOTIFY_COLOR are available from palette.sh via lib.sh.

print_entry() {
  local notify="${3:-0}" color="" reset=""
  if [ "$notify" = 1 ]; then
    color=$PAL_GOLD
    reset=$PAL_RESET
  fi
  printf '%s\t%s%s%s\n' "$1" "$color" "$2" "$reset"
}

# fetch_panes SCOPE FILTER — populate label_of and order for the given scope.
# Results are returned in the caller's arrays (label_of, order).
fetch_panes() {
  local scope="${1:-current}" filter="${2:-}" \
        current_pane_id current_session \
        pane label bell session session_id
  # shellcheck disable=SC2034 # read via mru_merge nameref only
  declare -A allowed=()

  current_pane_id=$(current_pane)
  if [ -n "$current_pane_id" ]; then
    current_session=$(tmux display-message -p -t "$current_pane_id" '#{session_id}' 2>/dev/null || true)
  fi
  [ -n "${current_session:-}" ] || current_session=$(current_session_id 2>/dev/null || true)

  if [ -n "$filter" ]; then
    while IFS= read -r pane; do
      [ -n "$pane" ] && allowed[$pane]=1
    done < <(matching_ids "$filter")
  fi

  while IFS=$'\t' read -r pane label bell session session_id; do
    [ -n "$pane" ] || continue
    is_hidden_session "$session" && continue
    if [ "$scope" = current ] && [ -n "$current_session" ] && [ "$session_id" != "$current_session" ]; then
      continue
    fi
    [ -n "$filter" ] && [ -z "${allowed[$pane]+x}" ] && continue
    # Pre-format with bell colours so mru_merge can emit directly.
    # shellcheck disable=SC2034 # read via mru_merge nameref
    label_of[$pane]=$(print_entry "$pane" "$label" "${bell:-0}")
    order+=("$pane")
  done < <(tmux list-panes -a -F "$FIELDS" 2>/dev/null)
}

# list SCOPE FILTER — MRU-ordered "<pane_id><TAB><label>" for fzf, current pane
# omitted so Enter jumps back to where you came from.
list() {
  local scope="${1:-current}" filter="${2:-}" current
  # shellcheck disable=SC2034 # read via mru_merge nameref
  declare -A label_of=() listed=()
  local order=()

  fetch_panes "$scope" "$filter"

  current=$(current_pane)

  local -n _mru_order=order _mru_row=label_of _mru_listed=listed
  mru_merge "$HISTORY" "$current" _mru_order _mru_row _mru_listed
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
  local current pane session
  current=$(current_pane)

  if [ -f "$HISTORY" ]; then
    while IFS= read -r pane; do
      [ -n "$pane" ] || continue
      [ "$pane" = "$current" ] && continue
      session=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null) || continue
      is_hidden_session "$session" && continue
      focus_pane "$pane" && return 0
    done <"$HISTORY"
  fi

  # No usable history: fall back to tmux's own last-pane.
  tmux last-pane 2>/dev/null || true
}

# True when there is at least one other pane to show. The key bindings use
# this before opening a popup, so an empty picker never flashes the screen.
has() {
  local scope="${1:-current}" filter="${2:-}" out

  out=$(list "$scope" "$filter")

  [ -n "$out" ]
}

pick() {
  mkdir -p "$(dirname "$HISTORY")" 2>/dev/null || true
  touch "$HISTORY"

  local scope="${1:-current}" filter="${2:-}" list_cmd label scope_name pane
  list_cmd="$SELF list $scope"
  [ -n "$filter" ] && list_cmd="$list_cmd $filter"

  pane=$(current_pane)
  if [ -n "$pane" ]; then
    scope_name=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null || true)
  fi
  [ -n "${scope_name:-}" ] || scope_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
  if [ "$scope" = all ]; then
    scope_name="all sessions"
  fi
  [ -n "$scope_name" ] || scope_name="session"

  if [ -n "$filter" ]; then
    case "$filter" in
      opencode) label=" 󰚩 opencode · $scope_name " ;;
      nvim)     label="  nvim · $scope_name " ;;
      *)        label=" $filter · $scope_name " ;;
    esac
  else
    label="  panes · $scope_name "
  fi

  # Build the list once: it is both the emptiness check and fzf's input.
  local entries selection
  entries=$(list "$scope" "$filter")
  if [ -z "$entries" ]; then
    if [ -n "$filter" ]; then
      tmux display-message -d 1500 "no $filter panes"
    else
      tmux display-message -d 1500 "no panes"
    fi
    return 0
  fi

  selection=$(
    printf '%s\n' "$entries" | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      "${FZF_STYLE[@]}" \
      --border-label="$label" \
      --header="enter: go · ctrl-x: kill · ctrl-d: close session · ctrl-o: new window · ctrl-v: preview · ctrl-r: reload" \
      --preview 'tmux capture-pane -p -e -t {1} -S -200' \
      --preview-window='right,60%,border-left' \
      --bind "ctrl-x:execute-silent(tmux kill-pane -t {1})+reload($list_cmd)" \
      --bind "ctrl-d:execute-silent($SELF close-session {1})+reload($list_cmd)" \
      --bind "ctrl-o:execute-silent($SELF open-window {1})+abort" \
      --bind 'ctrl-v:toggle-preview' \
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
  list) shift; list "${1:-current}" "${2:-}" ;;
  last) last ;;
  pick) shift; pick "${1:-current}" "${2:-}" ;;
  has) shift; has "${1:-current}" "${2:-}" ;;
  open-window) shift; open_window "${1:-}" ;;
  close-session) shift; close_session "${1:-}" ;;
  *)
    printf 'usage: %s {save [pane_id]|prune|list [SCOPE] [FILTER]|last|pick [SCOPE] [FILTER]|has [SCOPE] [FILTER]|open-window <pane_id>|close-session <pane_id>}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
