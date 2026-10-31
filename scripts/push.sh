#!/usr/bin/env bash
# push.sh — push submodules before the parent repository.
#
# A parent commit points at a submodule commit through a gitlink. Pushing the
# parent first leaves everyone else with a reference they cannot fetch, so this
# refuses to run while a submodule has no upstream or unpushed commits.
#
#   scripts/push.sh             check, push submodules, then the parent
#   scripts/push.sh --dry-run   show what would be pushed

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

dry=0
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) dry=1 ;;
    -h|--help)
      printf 'usage: %s [--dry-run]\n' "${0##*/}"
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$arg" >&2
      printf 'usage: %s [--dry-run]\n' "${0##*/}" >&2
      exit 2
      ;;
  esac
done

if ! git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  printf 'parent branch has no upstream; set one with: git push -u origin HEAD\n' >&2
  exit 1
fi

paths=()
while IFS= read -r line; do
  [ -n "$line" ] && paths+=("${line#* }")
done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null)

fail=0
ahead_paths=()

for path in "${paths[@]}"; do
  if [ ! -d "$path/.git" ] && [ ! -f "$path/.git" ]; then
    printf '  %s: not initialized\n' "$path" >&2
    fail=1
    continue
  fi

  if ! upstream=$(git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null); then
    printf '  %s: no upstream branch\n' "$path" >&2
    fail=1
    continue
  fi

  ahead=$(git -C "$path" rev-list --count "$upstream..HEAD" 2>/dev/null) || ahead=0
  if [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
    printf '  %s: has uncommitted changes (not pushed)\n' "$path" >&2
  fi

  if [ "$ahead" -gt 0 ]; then
    printf '  %s: %s commit(s) ahead of %s\n' "$path" "$ahead" "$upstream"
    ahead_paths+=("$path")
  else
    printf '  %s: up to date\n' "$path"
  fi
done

if [ "$fail" -ne 0 ]; then
  printf '\nrefusing to push the parent until every submodule has an upstream\n' >&2
  exit 1
fi

for path in "${ahead_paths[@]}"; do
  printf '\npushing %s\n' "$path"
  if [ "$dry" -eq 1 ]; then
    git -C "$path" push --dry-run || fail=1
  else
    git -C "$path" push || fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  printf '\nsubmodule push failed; not pushing the parent\n' >&2
  exit 1
fi

printf '\npushing %s\n' "$(git rev-parse --abbrev-ref HEAD)"
if [ "$dry" -eq 1 ]; then
  git push --dry-run
else
  git push
fi
