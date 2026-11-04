#!/usr/bin/env bash
# ai.sh — fuzzy picker for daily `opencode run` prompts (M-c).
#
# Commands live in ${XDG_CONFIG_HOME:-$HOME/.config}/ai/run-commands.json:
#
#   {
#     "commands": [
#       {
#         "name": "commit",
#         "description": "Review and commit the current changes",
#         "prompt": "Inspect git status and diff ...",
#         "args": ["--auto"]
#       }
#     ]
#   }
#
#   ai.sh has             true when the file has valid commands
#   ai.sh list            TSV "name<TAB>name  description" for fzf
#   ai.sh list-mru        same rows, most recently run first
#   ai.sh preview NAME    show one command's full prompt
#   ai.sh pick            fzf picker, then run the selected command
#   ai.sh run NAME        run one command directly
#
# `args` is optional. Add "--auto" when the prompt needs tool permissions;
# there is no TUI in the popup to answer permission prompts. Each invocation
# starts a fresh session (pass "--continue" in args to opt into the last one).

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

COMMANDS="${AI_RUN_COMMANDS:-${XDG_CONFIG_HOME:-$HOME/.config}/ai/run-commands.json}"

STATE_DIR=$(tmux_state_dir)
MRU="${AI_COMMAND_HISTORY:-$STATE_DIR/ai-commands}"
LIMIT="${AI_COMMAND_HISTORY_LIMIT:-50}"

SESSION_NAME="ai runner"

record() {
  [ -n "${1:-}" ] || return 0
  mru_push "$MRU" "$1" "$LIMIT"
}

# Generate a unique window name under the ai runner session by appending a
# numeric suffix when the base name is already taken.
unique_window() {
  local base="$1" n=2
  local name="$base"
  while tmux list-windows -t "$SESSION_NAME" -F '#{window_name}' 2>/dev/null | grep -qxF "$name"; do
    name="${base}-$((n++))"
  done
  printf '%s\n' "$name"
}

# load_command NAME — query prompt and args from the commands file.
# Sets $prompt and $extra (array) in the caller's scope; returns non-zero
# when the command is unknown or opencode is not installed.
load_command() {
  local name="${1:-}"
  prompt="" extra=()
  shift 2>/dev/null || true

  [ -n "$name" ] || return 2

  prompt=$(jq -r --arg name "$name" '
    (if type == "array" then . else .commands // [] end)[]
    | select(.name == $name)
    | .prompt
  ' "$COMMANDS")

  if [ -z "$prompt" ]; then
    printf 'unknown ai command: %s\n' "$name"
    return 1
  fi

  mapfile -t extra < <(jq -r --arg name "$name" '
    (if type == "array" then . else .commands // [] end)[]
    | select(.name == $name)
    | (.args // [])[]
  ' "$COMMANDS")

  if ! command -v opencode >/dev/null 2>&1; then
    printf 'opencode not found in PATH\n'
    return 127
  fi
}

# Launch opencode run in a background pane so the user can keep working.
run_bg() {
  local name="${1:-}" prompt="" rc
  local -a extra=()
  shift

  if [ -z "$name" ]; then
    printf 'usage: run_bg NAME [ARGS...]\n' >&2
    hold
    return 2
  fi

  load_command "$name" || { rc=$?; hold; return "$rc"; }

  record "$name"

  # Ensure the detached ai runner session exists.
  if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -n "init" 2>/dev/null || {
      printf 'could not create session "%s"\n' "$SESSION_NAME"
      hold
      return 1
    }
  fi

  local window_name
  window_name=$(unique_window "run-${name}")

  local pane
  pane=$(tmux new-window -d -P -F '#{pane_id}' \
    -t "$SESSION_NAME" -n "$window_name" -c '#{pane_current_path}' 2>/dev/null) || {
    printf 'could not create window in session "%s"\n' "$SESSION_NAME"
    hold
    return 1
  }

  # Build the command that runs inside the pane. After opencode exits it sends a
  # notification to the first attached client (if any) and then prints a status
  # line so the window retains a record of the outcome.
  local esc_prompt esc_name
  printf -v esc_prompt '%q' "$prompt"
  printf -v esc_name '%q' "$name"

  # Build args string (already safe strings from jq, but quote them anyway).
  local args_str="" a
  for a in "${extra[@]}"; do
    printf -v args_str '%s %q' "$args_str" "$a"
  done

  # We pipe the multi-line command through bash -s so quoting is straightforward.
  local script
  read -r -d '' script <<-SCRIPT || true
	__client=\$(tmux list-clients -F '#{client_name}' 2>/dev/null | head -1)
	opencode run --title "run · ${esc_name}" ${args_str} ${esc_prompt}
	__rc=\$?
	if [ -n "\$__client" ]; then
	  if [ "\$__rc" -eq 0 ]; then
	    tmux display-message -d 3000 -t "\$__client" "✓ done · ${esc_name}"
	  else
	    tmux display-message -d 3000 -t "\$__client" "✗ failed (\$__rc) · ${esc_name}"
	  fi
	fi
	printf '\n[done · %s]\n' "${esc_name}"
	SCRIPT

  tmux send-keys -t "$pane" "$script" Enter

  printf 'launched in "%s:%s"\n' "$SESSION_NAME" "$window_name"
}

valid() {
  command -v jq >/dev/null 2>&1 || return 1
  [ -r "$COMMANDS" ] || return 1

  if jq -e '
    (if type == "array" then . else .commands // [] end) as $commands
    | ($commands | type == "array")
      and ($commands | length > 0)
      and ($commands | all(.[];
        (.name | type == "string")
        and (.name | test("^[^\\t\\r\\n]+$"))
        and ((.description // "") | type == "string")
        and ((.prompt // "") | type == "string")
        and ((.prompt // "") | length > 0)
        and (((.args // []) | type == "array")
             and ((.args // []) | all(.[]; type == "string")))
      ))
      and (($commands | map(.name) | length)
           == ($commands | map(.name) | unique | length))
  ' "$COMMANDS" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

has() {
  valid
}

# Show the full prompt and flags for one command.
preview() {
  local name="${1:-}"

  jq -r --arg name "$name" '
    (if type == "array" then . else .commands // [] end)[]
    | select(.name == $name)
    | .name,
      "",
      (.description // ""),
      "",
      (if ((.args // []) | length) > 0
       then "args: " + ((.args // []) | join(" ")) + "\n"
       else "" end),
      .prompt
  ' "$COMMANDS"
}

# "name<TAB>name  description", with the name and description in rose-pine
# colours. fzf searches the whole line, so descriptions are searchable too.
list() {
  jq -r --arg name_color "$PAL_IRIS" \
        --arg desc_color "$PAL_SUBTLE" \
        --arg reset "$PAL_RESET" '
    (if type == "array" then . else .commands // [] end)[]
    | [.name,
       ($name_color + .name + $reset
        + (if ((.description // "") | gsub("\\s+"; " ")) != ""
           then "  " + $desc_color
                + ((.description // "") | gsub("\\s+"; " ")) + $reset
           else "" end))]
    | @tsv
  ' "$COMMANDS"
}

# Same rows, but ordered like the other pickers: most recently run first.
list_mru() {
  local name rest
  # shellcheck disable=SC2034 # read via mru_merge nameref
  declare -A row_of=() listed=()
  local order=()

  while IFS=$'\t' read -r name rest; do
    [ -n "$name" ] || continue
    # shellcheck disable=SC2034 # read via mru_merge nameref
    row_of[$name]="$name"$'\t'"$rest"
    order+=("$name")
  done < <(list)

  local -n _mru_order=order _mru_row=row_of _mru_listed=listed
  mru_merge "$MRU" "" _mru_order _mru_row _mru_listed
}

hold() {
  [ -t 0 ] || return 0
  printf '\npress any key to close'
  IFS= read -rsn1 || true
  printf '\n'
}

run() {
  local name="${1:-}" prompt="" title rc
  local -a extra=()

  load_command "$name" || { rc=$?; hold; return "$rc"; }

  record "$name"

  title="run · $name"
  opencode run --title "$title" "${extra[@]}" "$prompt"
  rc=$?

  printf '\n'
  if [ "$rc" -eq 0 ]; then
    printf 'done · %s\n' "$name"
  else
    printf 'failed (%d) · %s\n' "$rc" "$name"
  fi
  hold
  return "$rc"
}

pick() {
  if ! valid; then
    printf 'no valid commands in %s\n' "$COMMANDS"
    hold
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    printf 'fzf not found in PATH\n'
    hold
    return 1
  fi

  local selection name
  selection=$(
    list_mru | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --no-sort \
      "${FZF_STYLE[@]}" \
      --border-label=' ai run ' \
      --header='enter: run · ctrl-h: details · ctrl-v: preview · ctrl-r: reload' \
      --preview "$SELF preview {1}" \
      --preview-window='right,60%,border-left,wrap,hidden' \
      --preview-label=' details ' \
      --bind 'ctrl-h:toggle-preview' \
      --bind 'ctrl-v:toggle-preview' \
      --bind "ctrl-r:reload($SELF list-mru)"
  )

  [ -n "$selection" ] || return 0
  name=${selection%%$'\t'*}
  run_bg "$name"
}

case "${1:-}" in
  has) has ;;
  list) list ;;
  list-mru) list_mru ;;
  preview) shift; preview "${1:-}" ;;
  pick) pick ;;
  run) shift; run "${1:-}" ;;
  *)
    printf 'usage: %s {has|list|list-mru|preview NAME|pick|run NAME}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
