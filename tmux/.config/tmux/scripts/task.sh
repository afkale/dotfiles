#!/usr/bin/env bash
# task.sh — create and open task worktrees via workmux (M-W).
#
#   task.sh prompt        ask for a task name, validate, then delegate to workmux
#   task.sh new NAME      validate and create/reopen a workmux task
#
# This is the glue between tmux keybindings and workmux. It validates the
# branch name before delegating so invalid names never reach workmux.
# workmux is responsible for the actual worktree/window creation.
#
# When the branch already exists (or a worktree for it exists), workmux's
# --open-if-exists reopens the existing checkout in the current session.
#
# The popup binding uses -E (close on exit), so error messages must be shown
# via tmux display-message. For longer errors, use hold_always() from lib.sh.

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

new() {
  local name=${1:-}
  [ -n "$name" ] || {
    message "no name given"
    return 1
  }

  validate_name "$name" || return 1

  if ! command -v workmux >/dev/null 2>&1; then
    message "workmux not installed"
    return 1
  fi

  # Delegate to workmux. --open-if-exists handles both "new branch" and
  # "branch already has a worktree" cases.
  workmux add --open-if-exists "$name" 2>&1 || {
    message "workmux add failed"
    return 1
  }
}

prompt() {
  if ! command -v workmux >/dev/null 2>&1; then
    message "workmux not installed"
    exit 1
  fi

  printf '\n  new task worktree\n\n'
  printf '  name: '
  IFS= read -r name || exit 1
  [ -n "$name" ] || exit 0

  new "$name"
}

# Guard: only dispatch when executed directly, not sourced (for tests).
(return 0 2>/dev/null) && return 0

case "${1:-}" in
  prompt) prompt ;;
  new) shift; new "${1:-}" ;;
  *)
    printf 'usage: %s {prompt|new NAME}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
