#!/usr/bin/env bash
# ai.sh — fuzzy picker for daily `ai run` prompts (M-c).
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
#   ai.sh has                 true when the file has valid commands
#   ai.sh list                TSV "name<TAB>name  description" for fzf
#   ai.sh preview NAME        show one command's full prompt
#   ai.sh pick                fzf picker, then launch the selection
#   ai.sh launch NAME         launch in the dedicated session without switching
#   ai.sh run NAME            run directly in this terminal
#   ai.sh run-window [NAME]   run in a window kept after exit
#
# Launches go to a dedicated tmux session (AI_RUN_SESSION, default "ai-runs")
# as a new window, so the current pane/session is untouched.
#
# Provider: opencode. It is the only backend wired up for now; the runner is
# branded generically as `ai run`.
#
# Environment knobs (provider defaults are opencode-specific):
#   AI_RUN_PROVIDER=opencode
#   AI_RUN_PROVIDER_ARGS=            # global args; e.g. --auto for every command
#   AI_RUN_COMMANDS=~/.config/ai/run-commands.json
#   AI_RUN_SESSION=ai-runs
#
# Command-specific `args` in run-commands.json are appended after the global
# provider args, so avoid repeating the same flag in both places. The
# background window has no TUI to answer permission prompts, so commands that
# need tools use ["--auto"] there. Each invocation starts a fresh session
# unless args include "--continue".

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
COMMANDS="${AI_RUN_COMMANDS:-${XDG_CONFIG_HOME:-$HOME/.config}/ai/run-commands.json}"
RUN_SESSION="${AI_RUN_SESSION:-ai-runs}"
PROVIDER="${AI_RUN_PROVIDER:-opencode}"
PROVIDER_ARGS_STR="${AI_RUN_PROVIDER_ARGS:-}"
PROVIDER_ARGS=()
if [ -n "$PROVIDER_ARGS_STR" ]; then
  read -r -a PROVIDER_ARGS <<<"$PROVIDER_ARGS_STR"
fi

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

  printf 'provider: %s\nglobal args: %s\n\n' \
    "$PROVIDER" "${PROVIDER_ARGS_STR:-(none)}"

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

# Run one command from the JSON. No holding or shell: callers decide what to
# do after it exits.
execute() {
  local name="${1:-}" prompt title rc
  local -a extra=()

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

  if ! command -v "$PROVIDER" >/dev/null 2>&1; then
    printf '%s provider not found in PATH\n' "$PROVIDER"
    return 127
  fi

  title="ai run · $name"
  "$PROVIDER" run --title "$title" \
    "${PROVIDER_ARGS[@]}" "${extra[@]}" "$prompt"
  rc=$?

  printf '\n'
  if [ "$rc" -eq 0 ]; then
    printf 'done · %s\n' "$name"
  else
    printf 'failed (%d) · %s\n' "$rc" "$name"
  fi
  return "$rc"
}

# Direct, blocking invocation (used outside tmux and by `run`).
run() {
  local name="${1:-}"
  execute "$name"
  local rc=$?
  hold
  return "$rc"
}

# Invoked inside the dedicated tmux window. The window is kept after exit
# (remain-on-exit), so the output stays available in the pane picker.
set_pane_title() {
  local title="${1:-}"
  [ -n "${TMUX_PANE:-}" ] || return 0
  tmux select-pane -t "$TMUX_PANE" -T "$title" 2>/dev/null || true
}

run_window() {
  local name="${1:-${AI_RUN_NAME:-}}" title rc

  title="ai run: $name · $PROVIDER"
  set_pane_title "$title"

  execute "$name"
  rc=$?

  # The provider may change the terminal title while it runs; restore ours so
  # the finished job still shows up in the provider's M-o picker.
  set_pane_title "$title"
  return "$rc"
}

# Launch in the dedicated session. The current client is never switched.
launch() {
  local name="${1:-}" dir="$PWD" win cmd jobs_win

  [ -n "$name" ] || return 1

  # Outside tmux, fall back to the old blocking behaviour.
  if [ -z "${TMUX:-}" ] && [ -z "${TMUX_PANE:-}" ]; then
    run "$name"
    return
  fi

  if ! tmux has-session -t "=$RUN_SESSION" 2>/dev/null; then
    if ! tmux new-session -d -s "$RUN_SESSION" -n jobs -c "$HOME"; then
      printf 'failed to create tmux session: %s\n' "$RUN_SESSION"
      hold
      return 1
    fi

    jobs_win=$(tmux list-windows -t "=$RUN_SESSION" -F '#{window_id}' 2>/dev/null | head -1)
    if [ -n "$jobs_win" ]; then
      tmux set-window-option -t "$jobs_win" automatic-rename off 2>/dev/null || true
      tmux rename-window -t "$jobs_win" jobs 2>/dev/null || true
    fi
  fi

  cmd=$(printf '%q run-window' "$SELF")
  if ! win=$(tmux new-window -d -P -F '#{window_id}' \
    -t "=$RUN_SESSION:" \
    -n "ai: $name" \
    -c "$dir" \
    -e "AI_RUN_COMMANDS=$COMMANDS" \
    -e "AI_RUN_NAME=$name" \
    -e "AI_RUN_PROVIDER=$PROVIDER" \
    -e "AI_RUN_PROVIDER_ARGS=$PROVIDER_ARGS_STR" \
    "$cmd"); then
    printf 'failed to launch %s in %s\n' "$name" "$RUN_SESSION"
    hold
    return 1
  fi

  tmux set-window-option -t "$win" automatic-rename off 2>/dev/null || true
  tmux set-window-option -t "$win" remain-on-exit on 2>/dev/null || true
  tmux rename-window -t "$win" "ai: $name" 2>/dev/null || true
  tmux display-message -d 1500 \
    "launched ai run ($PROVIDER) in $RUN_SESSION" 2>/dev/null || true
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
      --border-label=" ai run · $PROVIDER " \
      --color='fg:#908caa,bg:#191724,hl:#eb6f92,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92' \
      --color='info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177' \
      --color='header:#6e6a86,border:#403d52,label:#c4a7e7,selected-bg:#26233a' \
      --header="enter: launch into $RUN_SESSION · ctrl-h: details · ctrl-r: reload · esc: cancel" \
      --preview "$SELF preview {1}" \
      --preview-window='right,55%,border-left,wrap,hidden' \
      --preview-label=' details ' \
      --bind 'ctrl-h:toggle-preview' \
      --bind "ctrl-r:reload($SELF list)"
  )

  [ -n "$selection" ] || return 0
  name=${selection%%$'\t'*}
  launch "$name"
}

case "${1:-}" in
  has) has ;;
  list) list ;;
  preview) shift; preview "${1:-}" ;;
  pick) pick ;;
  launch) shift; launch "${1:-}" ;;
  run) shift; run "${1:-}" ;;
  run-window) shift; run_window "${1:-}" ;;
  *)
    printf 'usage: %s {has|list|preview NAME|pick|launch NAME|run NAME|run-window [NAME]}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
