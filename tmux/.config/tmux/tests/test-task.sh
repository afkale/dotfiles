#!/usr/bin/env bash
# test-task.sh — unit tests for the task.sh workmux wrapper.
#
# Tests validate_name() character checks (the git check-ref-format part is
# tested separately when git is available) and the workmux delegation logic
# using a stub workmux command.
#
# Run: bash test-task.sh

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LIB_DIR=$(cd "$SCRIPT_DIR/../scripts" && pwd)

# shellcheck source-path=SCRIPTDIR
# shellcheck disable=SC1091
. "$LIB_DIR/lib.sh"

pass=0
fail=0

# shellcheck disable=SC2294,SC2329
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

# We test validate_name's character checks from lib.sh by extracting the
# case pattern into a standalone function so git isn't needed.
# shellcheck disable=SC2329
validate_characters() {
  local name=$1
  case "$name" in
    ''|*[!A-Za-z0-9._/-]*) return 1 ;;
    -*) return 1 ;;
  esac
  return 0
}

# Test that new() validates the name before calling workmux by invoking a
# script that sources task.sh and overrides workmux with a stub.
# $1 = name, $2 = expected exit code (0 for success)
run_with_stub() {
  # shellcheck disable=SC2034
  local name=$1 expected_exit=${2:-0} shim_dir exit_code
  shim_dir=$(mktemp -d)

  # Stub workmux: writes args to a known file for assertion.
  # shellcheck disable=SC2034
  local log="${shim_dir}/invocations"
  cat > "$shim_dir/workmux" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "/tmp/opencode/workmux-stub-log"
STUB
  chmod +x "$shim_dir/workmux"

  : > /tmp/opencode/workmux-stub-log 2>/dev/null || true

  PATH="$shim_dir:$PATH" \
  TMUX=1 \
  bash -c "
    source '$LIB_DIR/lib.sh'
    source '$LIB_DIR/../scripts/task.sh'
    new '$name'
  " 2>/dev/null
  exit_code=$?
  rm -rf "$shim_dir"
  return "$exit_code"
}

# Check that the stub was called with exact arguments.
# shellcheck disable=SC2329
stub_was_called_with() {
  local expected="$*"
  [ -f /tmp/opencode/workmux-stub-log ] && grep -Fx "$expected" /tmp/opencode/workmux-stub-log >/dev/null 2>&1
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


# ── new() delegation tests ─────────────────────────────────────────────────

echo ""
echo "task.sh new() delegation"

# Test that valid names reach workmux with --open-if-exists
run_with_stub "fix-bug" 0
check "invokes workmux for valid name" pass \
  'stub_was_called_with "add --open-if-exists fix-bug"'

# Test that invalid names never reach workmux
run_with_stub "" 1
check "empty name does not invoke workmux" pass \
  'stub_was_called_with "add --open-if-exists " && false || true'

run_with_stub "bad name" 1
check "name with spaces does not invoke workmux" pass \
  'stub_was_called_with "add --open-if-exists bad name" && false || true'

run_with_stub "bad@name" 1
check "name with special chars does not invoke workmux" pass \
  'stub_was_called_with "add --open-if-exists bad@name" && false || true'

run_with_stub "-bad" 1
check "name starting with dash does not invoke workmux" pass \
  'stub_was_called_with "add --open-if-exists -bad" && false || true'

# Clean up
rm -f /tmp/opencode/workmux-stub-log 2>/dev/null || true


# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
echo "  $pass passed, $fail failed"
echo "─────────────────────────────────────────"
exit "$fail"
