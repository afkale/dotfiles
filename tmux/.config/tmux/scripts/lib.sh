#!/usr/bin/env bash
# lib.sh — helpers shared by the tmux scripts in this directory.
#
# Sourced by pane.sh, sessions.sh, worktree.sh, ai.sh and streamux.sh.

# Derive our own directory so palette.sh can be found from any sourcing context.
# shellcheck source-path=SCRIPTDIR source=palette.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/palette.sh"

# Popup sessions are named "_hidden*" and never show up in pickers.
is_hidden_session() {
  case "${1:-}" in
    _hidden*) return 0 ;;
    *) return 1 ;;
  esac
}

# Hooks and popups know their pane through TMUX_PANE; fall back to tmux.
current_pane() {
  if [ -n "${TMUX_PANE:-}" ]; then
    printf '%s\n' "$TMUX_PANE"
  else
    tmux display-message -p '#{pane_id}' 2>/dev/null
  fi
}

current_session_id() {
  tmux display-message -p '#{session_id}' 2>/dev/null
}

# Client attached to a given session (needed when several terminals are open).
client_for_session() {
  local session="${1:-}" sid name
  [ -n "$session" ] || return 0

  while IFS=$'\t' read -r sid name; do
    if [ "$sid" = "$session" ]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(tmux list-clients -F '#{session_id}'$'\t''#{client_name}' 2>/dev/null)
}

# Transient message inside tmux, plain text otherwise.
message() {
  if [ -n "${TMUX:-}" ]; then
    tmux display-message -d 1500 "$*" 2>/dev/null || true
  else
    printf '%s\n' "$*"
  fi
}

# Default location for small pieces of tmux state (pane/session/worktree/ai MRU).
tmux_state_dir() {
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
}

# Shared look for every fzf menu in these scripts (panes, sessions, worktrees,
# ai). Defining it once keeps the menus visually identical; callers add their
# own --border-label, --header, preview and key bindings on top.
# Shellcheck sees this file on its own, but the array is used by the scripts
# that source it.
# shellcheck disable=SC2034
FZF_STYLE=(
  --cycle
  --ansi
  --info=inline
  --border=rounded
  --color="fg:${PAL_SUBTLE_HEX},bg:${PAL_BASE_HEX},hl:${PAL_LOVE_HEX},fg+:${PAL_TEXT_HEX},bg+:${PAL_OVERLAY_HEX},hl+:${PAL_LOVE_HEX}"
  --color="info:${PAL_IRIS_HEX},prompt:${PAL_IRIS_HEX},pointer:${PAL_ROSE_HEX},marker:${PAL_FOAM_HEX},spinner:${PAL_GOLD_HEX}"
  --color="header:${PAL_MUTED_HEX},border:${PAL_HL_MED_HEX},label:${PAL_IRIS_HEX},selected-bg:${PAL_OVERLAY_HEX}"
)

# mru_push FILE ITEM [LIMIT]
#
# Move ITEM to the front of FILE, a newest-first list with one item per line.
# Duplicates are dropped and the list is capped at LIMIT entries. Writes are
# serialized with flock when available, so hooks can call this concurrently.
mru_push() {
  local file=${1:-} item=${2:-} limit=${3:-100} dir tmp
  [ -n "$file" ] && [ -n "$item" ] || return 0
  case "$item" in *$'\n'*|*$'\r'*) return 0 ;; esac

  dir=$(dirname "$file")
  mkdir -p "$dir" 2>/dev/null || return 0

  # Use a subshell so the lock fd is automatically closed when we return.
  (
    if command -v flock >/dev/null 2>&1; then
      exec 9>>"$file.lock"
      flock -w 1 9 2>/dev/null || true
    fi

    tmp=$(mktemp "$dir/.mru.XXXXXX") || exit 0
    {
      printf '%s\n' "$item"
      [ -f "$file" ] && cat "$file"
    } | awk -v limit="$limit" \
          'length($0) && !seen[$0]++ && count++ < limit' >"$tmp"
    mv -f "$tmp" "$file"
  )
}

# mru_merge MRU_FILE CURRENT_ITEM ORDER_ARRAY ROW_MAP LISTED_MAP
#
# Print the rows in ROW_MAP (an associative array of "key<TAB>formatted-row")
# in MRU-file order first (skipping CURRENT_ITEM), then remaining rows in
# ORDER_ARRAY order. LISTED_MAP is an associative array used as a scratch set
# to track already-emitted keys — create it as an empty array before calling.
# Callers must use `local -n` (bash 4.3+ nameref) to pass array references.
#
# Example:
#   local -A row_of=() listed=()
#   local order=()
#   # ... populate row_of and order from the data source ...
#   local -n _mru_order=order _mru_row=row_of _mru_listed=listed
#   mru_merge "$MRU" "$current" _mru_order _mru_row _mru_listed
mru_merge() {
  local mru_file=$1 current_item=$2
  local -n _mr_order=$3 _mr_row=$4 _mr_listed=$5
  local key

  if [ -f "$mru_file" ]; then
    while IFS= read -r key; do
      [ -n "$key" ] || continue
      [ "$key" = "$current_item" ] && continue
      [ -n "${_mr_row[$key]+x}" ] || continue
      [ -n "${_mr_listed[$key]+x}" ] && continue
      printf '%s\n' "${_mr_row[$key]}"
      # shellcheck disable=SC2004
      _mr_listed[$key]=1
    done <"$mru_file"
  fi

  for key in "${_mr_order[@]}"; do
    [ "$key" = "$current_item" ] && continue
    [ -n "${_mr_listed[$key]+x}" ] && continue
    printf '%s\n' "${_mr_row[$key]}"
  done
}
