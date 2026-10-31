#!/usr/bin/env bash
# streamux.sh — toggle the asciinema session recording used by M-s / M-C-s.
#
# The recorder runs in a new terminal window. A pid file in the runtime
# directory keeps stop scoped to this session instead of killing every
# asciinema process on the machine.

set -u

RUNTIME_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/tmux-streamux-$(id -u)"

message() {
  tmux display-message -d 1500 "$*" 2>/dev/null || true
}

session_name() {
  tmux display-message -p '#{session_name}' 2>/dev/null
}

pid_path() {
  local session=$1 safe
  safe=$(printf '%s' "$session" | tr -c 'A-Za-z0-9_.-' '_')
  printf '%s/%s.pid\n' "$RUNTIME_DIR" "$safe"
}

runtime_dir() {
  if mkdir -p "$RUNTIME_DIR" 2>/dev/null && [ -O "$RUNTIME_DIR" ]; then
    chmod 700 "$RUNTIME_DIR" 2>/dev/null || true
    return 0
  fi
  return 1
}

start() {
  local session file term
  session=$(session_name) || return 1
  [ -n "$session" ] || return 1

  file=$(pid_path "$session")
  if [ -s "$file" ]; then
    if kill -0 "$(cat "$file" 2>/dev/null)" 2>/dev/null; then
      message "already recording $session"
      return 0
    fi
    rm -f "$file"
  fi

  if ! command -v asciinema >/dev/null 2>&1; then
    message "asciinema not found"
    return 1
  fi

  term="${TERMINAL:-ghostty}"
  if ! command -v "${term%% *}" >/dev/null 2>&1; then
    message "terminal not found: ${term%% *}"
    return 1
  fi

  runtime_dir || {
    message "cannot create runtime directory"
    return 1
  }

  tmux set -g @logofg "#eb6f92"
  # $$ becomes the asciinema pid after exec, so stop can target just this one.
  read -r -a term_cmd <<<"$term"
  # shellcheck disable=SC2016 # $$, $1 and "$@" belong to the inner shell
  "${term_cmd[@]}" -e sh -c 'printf "%s\n" "$$" >"$1"; shift; exec "$@"' sh "$file" \
    asciinema stream -r -c "env -u TMUX tmux attach -t '$session'"
}

stop() {
  local session file pid
  session=$(session_name) || return 1
  [ -n "$session" ] || return 1

  file=$(pid_path "$session")
  tmux set -g @logofg "#c4a7e7"

  if [ ! -s "$file" ]; then
    message "not recording $session"
    return 0
  fi

  pid=$(cat "$file" 2>/dev/null) || pid=""
  rm -f "$file"

  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    # Stop the attached tmux client first, then the recorder itself.
    pkill -P "$pid" 2>/dev/null || true
    kill "$pid" 2>/dev/null || true
    message "stopped recording $session"
  else
    message "recording already stopped"
  fi
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  *)
    printf 'usage: %s {start|stop}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
