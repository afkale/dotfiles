#!/usr/bin/env bash
# popup_test.sh — checks that every popup open starts in the directory it was
# opened from (issue #9). Runs popup.sh on a throwaway tmux socket, under a
# pseudo-terminal so the final attach works, and never touches the real server.

set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POPUP="$HERE/popup.sh"

unset TMUX

SOCKET="popup-test-$$"
SESSION="_hidden_popup_test"
export TMUX_POPUP_SOCKET="$SOCKET"
export TMUX_POPUP_SESSION="$SESSION"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/popup-test.XXXXXX")"
DIR_A="$WORK/project a"
DIR_B="$WORK/project-b"
mkdir -p "$DIR_A" "$DIR_B"

PID=""
# shellcheck disable=SC2329
cleanup() {
  [ -n "$PID" ] && kill "$PID" 2>/dev/null
  tmux -L "$SOCKET" kill-server 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

fail=0
pass() { printf '  ok   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; fail=1; }

# Open the popup from $1 (as display-popup does), wait until it is attached,
# then set CWD to the current directory of the popup pane.
open_popup() {
  (cd "$1" && exec script -qfc "$POPUP" /dev/null) >/dev/null 2>&1 &
  PID=$!
  for _ in $(seq 1 50); do
    tmux -L "$SOCKET" has-session -t "=$SESSION" 2>/dev/null && break
    sleep 0.1
  done
  sleep 0.5
  CWD=$(tmux -L "$SOCKET" display -p -t "$SESSION:" '#{pane_current_path}' 2>/dev/null)
}

# Close the popup the way M-1 does: the client detaches.
close_popup() {
  tmux -L "$SOCKET" detach-client -s "$SESSION" 2>/dev/null
  kill "$PID" 2>/dev/null
  wait "$PID" 2>/dev/null
  PID=""
}

open_popup "$DIR_A"
if [ "$CWD" = "$DIR_A" ]; then
  pass "first open starts in the current directory"
else
  bad "first open: expected '$DIR_A', got '$CWD'"
fi
close_popup

open_popup "$DIR_B"
if [ "$CWD" = "$DIR_B" ]; then
  pass "open from another directory starts there"
else
  bad "second open: expected '$DIR_B', got '$CWD'"
fi
close_popup

if [ "$fail" -eq 0 ]; then
  printf 'popup tests passed\n'
else
  printf 'popup tests failed\n'
fi
exit "$fail"
