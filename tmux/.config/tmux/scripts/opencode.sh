#!/usr/bin/env bash
# opencode.sh — fuzzy picker for daily `opencode run` prompts (M-c).
#
# Commands live in ${XDG_CONFIG_HOME:-$HOME/.config}/opencode/run-commands.json:
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
#   opencode.sh has             true when the file has valid commands
#   opencode.sh list            TSV "name<TAB>name  description" for fzf
#   opencode.sh preview NAME    show one command's full prompt
#   opencode.sh pick            fzf picker, then run the selected command
#   opencode.sh run NAME        run one command directly
#
# `args` is optional. Add "--auto" when the prompt needs tool permissions;
# there is no TUI in the popup to answer permission prompts. Each invocation
# starts a fresh session (pass "--continue" in args to opt into the last one).

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
COMMANDS="${OPENCODE_RUN_COMMANDS:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/run-commands.json}"

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
    printf 'unknown opencode command: %s\n' "$name"
    hold
    return 1
  fi

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
    list | fzf \
      --delimiter=$'\t' \
      --with-nth=2.. \
      --cycle \
      --ansi \
      --info=inline \
      --border=rounded \
      --border-label=' opencode run ' \
      --color='fg:#908caa,bg:#191724,hl:#eb6f92,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92' \
      --color='info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177' \
      --color='header:#6e6a86,border:#403d52,label:#c4a7e7,selected-bg:#26233a' \
      --header='enter: run · ctrl-h: details · ctrl-r: reload · esc: cancel' \
      --preview "$SELF preview {1}" \
      --preview-window='right,55%,border-left,wrap,hidden' \
      --preview-label=' details ' \
      --bind 'ctrl-h:toggle-preview' \
      --bind "ctrl-r:reload($SELF list)"
  )

  [ -n "$selection" ] || return 0
  name=${selection%%$'\t'*}
  run "$name"
}

case "${1:-}" in
  has) has ;;
  list) list ;;
  preview) shift; preview "${1:-}" ;;
  pick) pick ;;
  run) shift; run "${1:-}" ;;
  *)
    printf 'usage: %s {has|list|preview NAME|pick|run NAME}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
