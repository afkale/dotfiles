#!/usr/bin/env bash
# test-lib.sh — unit tests for pure functions in lib.sh and palette.sh.
#
# Run: bash test-lib.sh
# These tests do not require tmux or any other external tool.

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR=$(cd "$SCRIPT_DIR/../scripts" && pwd)

# shellcheck source-path=SCRIPTDIR
. "$LIB_DIR/palette.sh"
# shellcheck source-path=SCRIPTDIR
. "$LIB_DIR/lib.sh"

pass=0
fail=0

check() {
  local label=$1 expected=$2
  shift 2
  if eval "$@"; then
    if [ "$expected" = pass ]; then
      echo "  ✓ $label"
      pass=$((pass + 1))
    else
      echo "  ✗ $label (expected $expected, got pass)"
      fail=$((fail + 1))
    fi
  else
    if [ "$expected" = fail ]; then
      echo "  ✓ $label"
      pass=$((pass + 1))
    else
      echo "  ✗ $label (expected $expected, got fail)"
      fail=$((fail + 1))
    fi
  fi
}

# ── is_hidden_session ──────────────────────────────────────────────────────

echo "is_hidden_session"

check "rejects empty string" fail \
  'is_hidden_session ""'

check "rejects normal name" fail \
  'is_hidden_session "main"'

check "rejects normal name with underscore" fail \
  'is_hidden_session "my_session"'

check "accepts _hidden prefix" pass \
  'is_hidden_session "_hidden_popup"'

check "accepts bare _hidden" pass \
  'is_hidden_session "_hidden"'

check "rejects _hidden without underscore prefix" fail \
  'is_hidden_session "not_hidden"'





# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
echo "  $pass passed, $fail failed"
echo "─────────────────────────────────────────"
exit "$fail"
