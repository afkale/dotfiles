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

record() {
  [ -n "${1:-}" ] || return 0
  mru_push "$MRU" "$1" "$LIMIT"
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
  local name_color=$'\033[38;2;196;167;231m'
  local desc_color=$'\033[38;2;144;140;170m'
  local reset=$'\033[0m'

  jq -r --arg name_color "$name_color" \
        --arg desc_color "$desc_color" \
        --arg reset "$reset" '
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
  declare -A row_of=() listed=()
  local order=()

  while IFS=$'\t' read -r name rest; do
    [ -n "$name" ] || continue
    row_of[$name]="$name"$'\t'"$rest"
    order+=("$name")
  done < <(list)

  if [ -f "$MRU" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      [ -n "${row_of[$name]+x}" ] || continue
      [ -n "${listed[$name]+x}" ] && continue
      printf '%s\n' "${row_of[$name]}"
      listed[$name]=1
    done <"$MRU"
  fi

  for name in "${order[@]}"; do
    [ -n "${listed[$name]+x}" ] && continue
    printf '%s\n' "${row_of[$name]}"
  done
}

hold() {
  [ -t 0 ] || return 0
  printf '\npress any key to close'
  IFS= read -rsn1 || true
  printf '\n'
}

run() {
  local name="${1:-}" prompt title rc
  local -a extra=()

  prompt=$(jq -r --arg name "$name" '
    (if type == "array" then . else .commands // [] end)[]
    | select(.name == $name)
    | .prompt
  ' "$COMMANDS")

  if [ -z "$prompt" ]; then
    printf 'unknown ai command: %s\n' "$name"
    hold
    return 1
  fi

  record "$name"

  mapfile -t extra < <(jq -r --arg name "$name" '
    (if type == "array" then . else .commands // [] end)[]
    | select(.name == $name)
    | (.args // [])[]
  ' "$COMMANDS")

  if ! command -v opencode >/dev/null 2>&1; then
    printf 'opencode not found in PATH\n'
    hold
    return 127
  fi

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
  run "$name"
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
