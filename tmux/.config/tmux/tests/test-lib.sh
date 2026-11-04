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


# ── mru_push ───────────────────────────────────────────────────────────────

echo ""
echo "mru_push"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

push_file="$WORKDIR/mru.txt"

# Empty file → first item
mru_push "$push_file" "item1" 10
check "creates file on first push" pass \
  '[[ -f $push_file ]] && [[ $(cat "$push_file") = "item1" ]]'

# Second item goes to front
mru_push "$push_file" "item2" 10
check "pushes to front" pass \
  '[[ $(head -1 "$push_file") = "item2" ]]'
check "keeps previous item" pass \
  '[[ $(wc -l < "$push_file") = 2 ]]'

# Duplicate moves to front
mru_push "$push_file" "item1" 10
check "dedup moves to front" pass \
  '[[ $(head -1 "$push_file") = "item1" ]]'
check "dedup removes duplicate" pass \
  '[[ $(wc -l < "$push_file") = 2 ]]'

# Limit enforcement
mru_push "$push_file" "a" 3
mru_push "$push_file" "b" 3
mru_push "$push_file" "c" 3
mru_push "$push_file" "d" 3
check "limit caps at 3 entries" pass \
  '[[ $(wc -l < "$push_file") = 3 ]]'
check "oldest item dropped" pass \
  '[[ $(tail -1 "$push_file") = "b" ]]'

# Empty item is a no-op
> "$push_file"
mru_push "$push_file" "" 10
check "empty item does not create file" pass \
  '[[ ! -f $push_file ]] || [[ ! -s $push_file ]]'

# Item with newline is rejected
> "$push_file"
mru_push "$push_file" $'multi\nline' 10
check "newline in item is rejected" pass \
  '[[ ! -f $push_file ]] || [[ ! -s $push_file ]]'

# Item with carriage return is rejected
> "$push_file"
mru_push "$push_file" $'carriage\rreturn' 10
check "CR in item is rejected" pass \
  '[[ ! -f $push_file ]] || [[ ! -s $push_file ]]'


# ── mru_merge ──────────────────────────────────────────────────────────────

echo ""
echo "mru_merge"

test_mru_merge() {
  local mru_file="$1" expected_first expected_last expected_skip
  declare -A row_of listed
  local order=()
  order=("a" "b" "c" "d")
  row_of["a"]=$'a\talpha'
  row_of["b"]=$'b\tbeta'
  row_of["c"]=$'c\tgamma'
  row_of["d"]=$'d\tdelta'

  expected_first=$'b\tbeta'
  expected_last=$'d\tdelta'
  expected_skip=$'a\talpha'

  # Without current item, should emit MRU order first (b, a, c) then remaining (d)
  listed=()
  local -n _o=order _r=row_of _l=listed
  result=$(mru_merge "$mru_file" "" _o _r _l 2>&1) || true
  check "mru_merge emits MRU-first order (b, a, c, d)" pass \
    '[[ $(head -1 <<< "$result") = "$expected_first" && $(tail -1 <<< "$result") = "$expected_last" ]]'
  check "mru_merge emits all 4 items" pass \
    '[[ $(wc -l <<< "$result") = 4 ]]'

  # With current=b, should skip b
  listed=()
  local -n _o2=order _r2=row_of _l2=listed
  result2=$(mru_merge "$mru_file" "b" _o2 _r2 _l2 2>&1) || true
  check "mru_merge skips current item" pass \
    '[[ $(head -1 <<< "$result2") = "$expected_skip" ]]'
  check "mru_merge emits 3 when skipping current" pass \
    '[[ $(wc -l <<< "$result2") = 3 ]]'
}

mru_file="$WORKDIR/mru_merge.txt"
printf 'b\na\nc\n' > "$mru_file"
test_mru_merge "$mru_file"


# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
echo "  $pass passed, $fail failed"
echo "─────────────────────────────────────────"
exit "$fail"
