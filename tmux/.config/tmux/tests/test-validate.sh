#!/usr/bin/env bash
# test-validate.sh — unit tests for name/command validation functions.
#
# Tests validate_name() character checks (the git check-ref-format part is
# tested separately when git is available) and the JSON validation logic.
#
# Run: bash test-validate.sh

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR=$(cd "$SCRIPT_DIR/../scripts" && pwd)

# We test validate_name's character checks by extracting the case pattern and
# the '-' check into a standalone function so git isn't needed.
validate_characters() {
  local name=$1
  case "$name" in
    ''|*[!A-Za-z0-9._/-]*) return 1 ;;
    -*) return 1 ;;
  esac
  return 0
}

# For ai.sh:valid we test the schema logic without the file read.
# The real valid() does: commands is an array, each has name (string, no tabs),
# description (string), prompt (non-empty string), args (array of strings),
# and unique names.
check_json() {
  local json=$1
  jq -e '
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
  ' <<< "$json" >/dev/null 2>&1
}

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

# ── validate_characters (name validation without git) ──────────────────────

echo "validate_characters"

check "rejects empty name" fail \
  'validate_characters ""'

check "rejects name with spaces" fail \
  'validate_characters "bad name"'

check "rejects name with special chars" fail \
  'validate_characters "bad@name"'

check "rejects name with exclamation" fail \
  'validate_characters "bad!"'

check "rejects name starting with dash" fail \
  'validate_characters "-bad"'

check "accepts simple name" pass \
  'validate_characters "fix-bug"'

check "accepts name with slash (branch prefix)" pass \
  'validate_characters "feat/foo"'

check "accepts name with dots" pass \
  'validate_characters "v1.2.3"'

check "accepts name with underscores" pass \
  'validate_characters "my_feature"'

check "accepts alphanumeric" pass \
  'validate_characters "feature123"'


# ── JSON validation (ai.sh:valid) ──────────────────────────────────────────

echo ""
echo "JSON validation"

check "accepts valid commands array" pass \
  'check_json '\''{"commands":[{"name":"test","description":"A test","prompt":"do something"}]}'\'''

check "accepts commands with args" pass \
  'check_json '\''{"commands":[{"name":"test","prompt":"do","args":["--auto"]}]}'\'''

check "accepts bare array format" pass \
  'check_json '\''[{"name":"test","prompt":"do"}]'\'''

check "rejects empty commands" fail \
  'check_json '\''{}'\'''

check "rejects empty commands array" fail \
  'check_json '\''{"commands":[]}'\'''

check "rejects missing prompt" fail \
  'check_json '\''{"commands":[{"name":"test"}]}'\'''

check "rejects empty prompt" fail \
  'check_json '\''{"commands":[{"name":"test","prompt":""}]}'\'''

check "rejects duplicate names" fail \
  'check_json '\''{"commands":[{"name":"test","prompt":"a"},{"name":"test","prompt":"b"}]}'\'''

check "rejects tab in name" fail \
  'check_json '\''{"commands":[{"name":"bad\tname","prompt":"do"}]}'\'''

check "rejects non-array args" fail \
  'check_json '\''{"commands":[{"name":"test","prompt":"do","args":"not-array"}]}'\'''


# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
echo "  $pass passed, $fail failed"
echo "─────────────────────────────────────────"
exit "$fail"
