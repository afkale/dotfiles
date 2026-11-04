#!/usr/bin/env bash
# sessions.sh — fuzzy session switcher and layout snapshots (M-s).
#
#   sessions.sh list              "<session_id><TAB><label>", MRU order, fzf input
#   sessions.sh pick              switch to the selected session (M-s)
#   sessions.sh record [NAME]     remember a session as most recently used
#   sessions.sh save [--quiet]    snapshot live sessions under $XDG_STATE_HOME
#   sessions.sh restore           recreate sessions missing from the snapshot
#   sessions.sh kill SESSION_ID   kill a session (picker Ctrl-x)
#
# Hidden popup sessions ("_hidden*") are excluded everywhere, like pane.sh.
# Snapshots are written when a client detaches and after window/pane changes.
# After a reboot run `sessions.sh restore`, then use M-s to switch sessions.

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SELF%/*}
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
SNAPSHOT="${TMUX_SESSION_STATE:-$STATE_DIR/sessions}"
MRU="${TMUX_SESSION_HISTORY:-$STATE_DIR/session-history}"
LIMIT="${TMUX_SESSION_HISTORY_LIMIT:-50}"
SEP=$'\x1f'

# Name of the session the picker was opened from. Popups know their pane via
# TMUX_PANE, so this also works from display-popup.
current_session_name() {
  local pane=${TMUX_PANE:-}
  if [ -z "$pane" ]; then
    pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null) || pane=''
  fi
  if [ -n "$pane" ]; then
    tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null && return 0
  fi
  tmux display-message -p '#{session_name}' 2>/dev/null
}

record() {
  local name=${1:-}
  [ -n "$name" ] || name=$(current_session_name)
  [ -n "$name" ] || return 0
  is_hidden_session "$name" && return 0
  mru_push "$MRU" "$name" "$LIMIT"
}

# Resolve a session id to a name and record it. Safer than #{session_name} in
# hooks (session IDs are "$N", which cannot break shell quoting).
record_id() {
  local id=${1:-} name
  [ -n "$id" ] || return 0
  name=$(tmux display-message -p -t "$id" '#{session_name}' 2>/dev/null) || return 0
  record "$name"
}

# Sessions ordered like the pane picker: the session visited before this one
# first (MRU history), then sessions never visited in plain tmux order. The
# current session is omitted, so Enter goes back to where you came from.
list() {
  local sid name windows attached current
  declare -A label_of=() listed=()
  local order=()

  current=$(current_session_name)

  while IFS=$'\t' read -r sid name windows attached; do
    [ -n "$name" ] || continue
    is_hidden_session "$name" && continue
    label_of[$name]="$sid"$'\t'"$name  $([ "$attached" = attached ] && printf '●' || printf '○')  ${windows}w"
    order+=("$name")
  done < <(tmux list-sessions -F \
    "#{session_id}"$'\t'"#{session_name}"$'\t'"#{session_windows}"$'\t'"#{?session_attached,attached,detached}" \
    2>/dev/null)

  if [ -f "$MRU" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      [ "$name" = "$current" ] && continue
      [ -n "${label_of[$name]+x}" ] || continue
      [ -n "${listed[$name]+x}" ] && continue
      printf '%s\n' "${label_of[$name]}"
      listed[$name]=1
    done <"$MRU"
  fi

  for name in "${order[@]}"; do
    [ "$name" = "$current" ] && continue
    [ -n "${listed[$name]+x}" ] && continue
    printf '%s\n' "${label_of[$name]}"
  done
}

focus_session() {
  local sid="${1:-}" client
  [ -n "$sid" ] || return 1

  client=$(client_for_session "$(current_session_id)")
  if [ -n "$client" ]; then
    tmux switch-client -c "$client" -t "$sid"
  else
    tmux switch-client -t "$sid"
  fi
  record "$(tmux display-message -p -t "$sid" '#{session_name}' 2>/dev/null)"
}

kill_session() {
  local sid="${1:-}" current
  [ -n "$sid" ] || return 0
  current=$(current_session_id) || current=""
  [ "$sid" = "$current" ] && return 0
  tmux kill-session -t "$sid" 2>/dev/null || true
}

pick() {
  local selection entries
  entries=$(list)
  if [ -z "$entries" ]; then
    message "no other sessions"
    return 0
  fi

  selection=$(
    printf '%s\n' "$entries" | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      "${FZF_STYLE[@]}" \
      --border-label='  sessions ' \
      --header='enter: switch · ctrl-s: save layout · ctrl-x: kill · ctrl-v: preview · ctrl-r: reload' \
      --preview 'tmux capture-pane -p -e -t {1} -S -200' \
      --preview-window='right,60%,border-left' \
      --bind "ctrl-s:execute-silent($SELF save)+reload($SELF list)" \
      --bind "ctrl-x:execute-silent($SELF kill {1})+reload($SELF list)" \
      --bind 'ctrl-v:toggle-preview' \
      --bind "ctrl-r:reload($SELF list)" \
      --bind 'enter:become(echo {1})'
  )

  [ -n "$selection" ] || return 0
  focus_session "$selection"
}

FIELDS="#{session_name}${SEP}#{window_index}${SEP}#{window_name}${SEP}#{pane_index}${SEP}#{pane_current_path}${SEP}#{pane_active}${SEP}#{window_active}${SEP}#{window_layout}"

save() {
  local quiet=0 panes tmp
  case "${1:-}" in -q|--quiet) quiet=1 ;; esac

  panes=$(tmux list-panes -a -F "$FIELDS" 2>/dev/null) || return 1

  mkdir -p "$(dirname "$SNAPSHOT")" 2>/dev/null || return 0
  tmp=$(mktemp "$(dirname "$SNAPSHOT")/.sessions.XXXXXX") || return 0

  printf '%s\n' "$panes" | grep -v $'^_hidden' >"$tmp" || true
  mv -f "$tmp" "$SNAPSHOT"

  [ "$quiet" -eq 1 ] || message "saved session layout"
}

restore() {
  [ -s "$SNAPSHOT" ] || {
    message "no session snapshot"
    return 1
  }

  declare -A session_state=() window_ids=() window_layout=() active_windows=()
  declare -A first_pane=() pane_ids=() active_pane_index=()
  local session win_idx win_name pane_idx cwd pane_active win_active layout
  local key win_id pane_id out created=0 skipped=0

  # Pass 1: create sessions and windows with their first pane. Existing
  # sessions are left alone so restore is safe to run more than once.
  while IFS="$SEP" read -r session win_idx win_name pane_idx cwd pane_active win_active layout; do
    [ -n "$session" ] || continue
    is_hidden_session "$session" && continue

    if [ -z "${session_state[$session]+x}" ]; then
      if tmux has-session -t "=$session" 2>/dev/null; then
        session_state[$session]=existing
        skipped=$((skipped + 1))
        continue
      fi

      [ -d "$cwd" ] || cwd="$HOME"
      if ! out=$(tmux new-session -d -P -F '#{window_id}|#{pane_id}' -s "$session" -n "$win_name" -c "$cwd" 2>/dev/null); then
        session_state[$session]=failed
        continue
      fi
      win_id=${out%%|*}
      pane_id=${out#*|}

      session_state[$session]=new
      created=$((created + 1))
      window_ids[$session:$win_idx]=$win_id
      window_layout[$win_id]=$layout
      active_windows[$session]=$win_id
      first_pane[$win_id]=$pane_idx
      pane_ids[$win_id:$pane_idx]=$pane_id
    else
      [ "${session_state[$session]}" = "new" ] || continue

      key="$session:$win_idx"
      if [ -z "${window_ids[$key]+x}" ]; then
        [ -d "$cwd" ] || cwd="$HOME"
        if ! out=$(tmux new-window -d -P -F '#{window_id}|#{pane_id}' -t "$session:$win_idx" -n "$win_name" -c "$cwd" 2>/dev/null); then
          continue
        fi
        win_id=${out%%|*}
        pane_id=${out#*|}
        window_ids[$key]=$win_id
        window_layout[$win_id]=$layout
        first_pane[$win_id]=$pane_idx
        pane_ids[$win_id:$pane_idx]=$pane_id
      else
        win_id=${window_ids[$key]}
      fi
    fi

    [ "$win_active" = 1 ] && active_windows[$session]=$win_id
    [ "$pane_active" = 1 ] && active_pane_index[$win_id]=$pane_idx
  done <"$SNAPSHOT"

  # Pass 2: add the remaining panes in reverse order. split-window inserts the
  # new pane at index 2 and shifts the others down, so descending creation
  # leaves the snapshot's pane order intact.
  while IFS="$SEP" read -r session win_idx win_name pane_idx cwd pane_active win_active layout; do
    [ -n "$session" ] || continue
    [ "${session_state[$session]:-}" = "new" ] || continue

    key="$session:$win_idx"
    win_id=${window_ids[$key]:-}
    [ -n "$win_id" ] || continue
    [ "$pane_idx" = "${first_pane[$win_id]:-}" ] && continue

    [ -d "$cwd" ] || cwd="$HOME"
    pane_id=$(tmux split-window -d -P -F '#{pane_id}' -t "$win_id" -c "$cwd" 2>/dev/null) || continue
    pane_ids[$win_id:$pane_idx]=$pane_id
    window_layout[$win_id]=$layout
  done < <(tac "$SNAPSHOT")

  # Apply the saved geometry once every pane in the window exists.
  for win_id in "${!window_layout[@]}"; do
    if [ -n "${window_layout[$win_id]}" ]; then
      tmux select-layout -t "$win_id" "${window_layout[$win_id]}" 2>/dev/null ||
        tmux select-layout -t "$win_id" tiled 2>/dev/null || true
    fi
  done

  for session in "${!active_windows[@]}"; do
    [ "${session_state[$session]}" = "new" ] || continue
    tmux select-window -t "${active_windows[$session]}" 2>/dev/null || true
  done

  for win_id in "${!active_pane_index[@]}"; do
    pane_id=${pane_ids[$win_id:${active_pane_index[$win_id]}]:-}
    [ -n "$pane_id" ] && tmux select-pane -t "$pane_id" 2>/dev/null || true
  done

  if [ "$created" -gt 0 ]; then
    message "restored $created session(s), skipped $skipped existing"
  else
    message "nothing to restore ($skipped session(s) already exist)"
  fi
}

case "${1:-}" in
  list) list ;;
  pick) pick ;;
  record) shift; record "${1:-}" ;;
  record-id) shift; record_id "${1:-}" ;;
  save) shift; save "${1:-}" ;;
  restore) restore ;;
  kill) shift; kill_session "${1:-}" ;;
  *)
    printf 'usage: %s {list|pick|record [SESSION_NAME]|record-id SESSION_ID|save|restore|kill SESSION_ID}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
