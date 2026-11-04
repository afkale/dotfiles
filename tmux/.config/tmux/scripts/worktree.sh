#!/usr/bin/env bash
# worktree.sh — create and manage task worktrees from tmux.
#
#   worktree.sh prompt        ask for a task name, then create and open it (M-C-t)
#   worktree.sh pick          fzf picker for existing worktrees (M-t)
#   worktree.sh open-all      open a window for every worktree (M-T)
#   worktree.sh new NAME      create a worktree and open it
#   worktree.sh list          TSV "path<TAB>branch<TAB>dirty" for fzf
#   worktree.sh list-mru      same rows, MRU order, current worktree omitted
#   worktree.sh preview PATH   show one worktree's status
#   worktree.sh open PATH      open (or focus) a tmux window for a worktree
#   worktree.sh remove PATH    remove a clean worktree, keeping its branch
#
# Worktrees live in ${WORKTREE_ROOT:-$HOME/worktrees}/<repo>/<branch>, with
# slashes in the branch replaced by dashes in the directory and window name.
# The branch keeps its real name, so typing feat/login creates branch
# feat/login in ~/worktrees/repo/feat-login.
#
# Override the root with the WORKTREE_ROOT environment variable.

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

WORKTREE_ROOT="${WORKTREE_ROOT:-$HOME/worktrees}"

STATE_DIR=$(tmux_state_dir)
MRU="${TMUX_WORKTREE_HISTORY:-$STATE_DIR/worktrees}"
LIMIT="${TMUX_WORKTREE_HISTORY_LIMIT:-100}"

# Print the canonical checkout for the current directory. Using the first
# worktree entry means this also works when called from a linked worktree.
# Popups normally start in the pane directory via -d; the TMUX_PANE fallback
# keeps the script working if it is invoked from somewhere else.
pane_path() {
  local pane=${TMUX_PANE:-}
  [ -n "$pane" ] || return 1
  tmux display-message -p -t "$pane" '#{pane_current_path}' 2>/dev/null
}

repo_root() {
  local dir=$PWD
  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    dir=$(pane_path) || return 1
    [ -n "$dir" ] || return 1
  fi
  git -C "$dir" worktree list --porcelain 2>/dev/null |
    sed -n 's/^worktree //p' |
    head -n 1
}

current_session() {
  tmux display-message -p '#{session_id}' 2>/dev/null
}

# Checkout the picker was opened from, used to skip the current worktree so
# Enter jumps to the worktree visited before this one.
current_worktree() {
  local dir=${1:-$PWD}
  if git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$dir" rev-parse --show-toplevel 2>/dev/null
    return 0
  fi
  dir=$(pane_path) || return 1
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null
}

record_worktree() {
  [ -n "${1:-}" ] || return 0
  mru_push "$MRU" "$1" "$LIMIT"
}

hold() {
  [ -t 0 ] || return 0
  printf '\npress any key to close'
  IFS= read -rsn1 || true
  printf '\n'
}

fail() {
  printf '\n%s\n' "$*" >&2
  hold
  exit 1
}

# Turn a branch name into a safe directory/window name.
slug() {
  printf '%s' "$1" | sed 's#/#-#g'
}

validate_name() {
  local name=$1
  case "$name" in
    ''|*[!A-Za-z0-9._/-]*)
      fail "invalid name: use letters, numbers, ., _, / or -"
      ;;
    -*)
      fail "invalid name: cannot start with -"
      ;;
  esac
  git check-ref-format --branch "$name" >/dev/null 2>&1 ||
    fail "invalid branch name: $name"
}

# Open (or focus) a tmux window for a worktree, running OpenCode in it.
open_worktree() {
  local path=${1:-} session name repo wid pane
  [ -n "$path" ] && [ -d "$path" ] || fail "not a directory: ${path:-}"

  record_worktree "$path"

  session=$(current_session) || fail "not running inside tmux"
  [ -n "$session" ] || fail "not running inside tmux"

  # Namespace the window by repository so two repos with the same branch name
  # do not fight over one window.
  case "$path" in
    "$WORKTREE_ROOT"/*)
      repo=$(basename "$(dirname "$path")")
      name="$repo/$(slug "$(basename "$path")")"
      ;;
    *)
      name=$(basename "$path")
      ;;
  esac
  name=${name//:/_}

  wid=$(tmux list-windows -t "$session" -F $'#{window_name}\t#{window_id}' 2>/dev/null |
    awk -F '\t' -v name="$name" '$1 == name { print $2; exit }')
  if [ -n "$wid" ]; then
    tmux select-window -t "$wid"
    return 0
  fi

  pane=$(tmux new-window -d -P -F '#{pane_id}' -c "$path" -n "$name" -t "$session" 2>/dev/null) ||
    fail "could not create a tmux window"

  if command -v opencode >/dev/null 2>&1; then
    tmux send-keys -t "$pane" 'opencode' Enter
  fi
  tmux select-window -t "$pane"
}

new_worktree() {
  local name=${1:-} root repo dir branch
  validate_name "$name"

  root=$(repo_root) || fail "not inside a git repository"
  repo=$(basename "$root")
  dir="$WORKTREE_ROOT/$repo/$(slug "$name")"
  branch=$name

  if [ -d "$dir" ]; then
    message "worktree already exists: $dir"
    open_worktree "$dir"
    return 0
  fi

  mkdir -p "$WORKTREE_ROOT/$repo" || fail "could not create $WORKTREE_ROOT/$repo"

  if git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$root" worktree add "$dir" "$branch" || fail "git worktree add failed"
  else
    git -C "$root" worktree add -b "$branch" "$dir" || fail "git worktree add failed"
  fi

  # A new worktree has no submodule checkouts even when the main one does.
  if [ -f "$root/.gitmodules" ]; then
    git -C "$dir" submodule update --init --recursive ||
      message "warning: submodule init failed in $dir"
  fi

  # Worktrees do not carry ignored files, so copy common local env files.
  # Use restricted perms (u=rw only) and skip envrc (it may execute on cd).
  local file
  for file in .env .env.local .env.development.local; do
    [ -f "$root/$file" ] || continue
    [ -L "$dir/$file" ] && continue  # never overwrite a tracked symlink
    install -m 600 -- "$root/$file" "$dir/$file" 2>/dev/null ||
      cp -p "$root/$file" "$dir/$file"
  done

  message "created $branch in $dir"
  open_worktree "$dir"
}

prompt_new() {
  local root repo name
  root=$(repo_root) || {
    printf '\nnot inside a git repository\n'
    hold
    exit 1
  }
  repo=$(basename "$root")

  printf '\n  new task worktree\n\n'
  printf '  repo: %s\n' "$repo"
  printf '  branch lives at: %s/%s/<name>\n\n' "$WORKTREE_ROOT" "$repo"
  printf '  name: '
  IFS= read -r name || exit 1
  [ -n "$name" ] || exit 0

  validate_name "$name"
  new_worktree "$name"
}

# TSV rows: path, branch, dirty marker. The picker hides the path column.
list_worktrees() {
  local root path branch dirty line
  root=$(repo_root) || return 1

  emit() {
    [ -n "$path" ] || return 0
    if [ -n "$(git -C "$path" status --porcelain 2>/dev/null | head -n 1)" ]; then
      dirty='*'
    else
      dirty=' '
    fi
    printf '%s\t%s\t%s\n' "$path" "${branch:-detached}" "$dirty"
  }

  path=''
  branch=''
  while IFS= read -r line; do
    case "$line" in
      'worktree '*)
        emit
        path=${line#worktree }
        branch=''
        ;;
      'branch '*)
        branch=${line#branch }
        branch=${branch#refs/heads/}
        ;;
      'detached')
        branch='detached'
        ;;
    esac
  done < <(git -C "$root" worktree list --porcelain 2>/dev/null)
  emit
}

list_mru() {
  local path branch dirty current
  # shellcheck disable=SC2034 # read via mru_merge nameref
  declare -A row_of=() listed=()
  local order=()

  while IFS=$'\t' read -r path branch dirty; do
    [ -n "$path" ] || continue
    # shellcheck disable=SC2034 # read via mru_merge nameref
    row_of[$path]="$path"$'\t'"$branch"$'\t'"$dirty"
    order+=("$path")
  done < <(list_worktrees)

  current=$(current_worktree 2>/dev/null || true)

  local -n _mru_order=order _mru_row=row_of _mru_listed=listed
  mru_merge "$MRU" "$current" _mru_order _mru_row _mru_listed
}

preview_worktree() {
  local path=${1:-}
  [ -n "$path" ] && [ -d "$path" ] || return 0

  printf '%s%s%s\n\n' "$PAL_IRIS" "$path" "$PAL_RESET"
  printf 'branch: %s\n' "$(git -C "$path" branch --show-current 2>/dev/null || echo detached)"
  printf 'head:   %s\n\n' "$(git -C "$path" log -1 --oneline 2>/dev/null)"
  git -C "$path" status --short 2>/dev/null | head -n 40
}

# Open or focus a window for every worktree in the repo, then return focus to
# the window that was active when the command started.
open_all_worktrees() {
  local path branch current count=0
  list_worktrees >/dev/null 2>&1 || fail "not inside a git repository"

  current=$(tmux display-message -p '#{window_id}' 2>/dev/null || true)
  while IFS=$'\t' read -r path branch _; do
    [ -n "$path" ] || continue
    open_worktree "$path"
    count=$((count + 1))
  done < <(list_worktrees)

  [ -n "$current" ] && tmux select-window -t "$current" 2>/dev/null
  message "opened $count worktrees"
}

# Focus a specific worktree window (create if needed) and record it in MRU.
focus_worktree() {
  local path=${1:-}
  [ -n "$path" ] && [ -d "$path" ] || { message "not a directory: ${path:-}"; return 1; }
  record_worktree "$path"
  open_worktree "$path"
}

pick_worktree() {
  local selection entries path scope_name
  list_worktrees >/dev/null 2>&1 || {
    printf 'not inside a git repository\n'
    hold
    return 1
  }

  scope_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
  [ -n "$scope_name" ] || scope_name="session"

  entries=$(list_mru)
  if [ -z "$entries" ]; then
    message "no other worktrees"
    return 0
  fi

  selection=$(
    printf '%s\n' "$entries" | fzf \
      --delimiter=$'\t' \
      --with-nth=2,3 \
      --no-sort \
      "${FZF_STYLE[@]}" \
      --border-label="  worktrees · $scope_name " \
      --header='enter: open · ctrl-x: remove · ctrl-v: preview · ctrl-r: reload · * = dirty' \
      --preview "$SELF preview {1}" \
      --preview-window='right,60%,border-left,wrap' \
      --bind 'ctrl-v:toggle-preview' \
      --bind "ctrl-r:reload($SELF list-mru)" \
      --bind "ctrl-x:execute-silent($SELF remove {1})+reload($SELF list-mru)"
  )

  [ -n "$selection" ] || return 0
  path=${selection%%$'\t'*}
  focus_worktree "$path"
}

remove_worktree() {
  local path=${1:-} root known=0 p session wid
  [ -n "$path" ] && [ -d "$path" ] || { message "not a directory: ${path:-}"; return 1; }
  root=$(repo_root) || { message "not inside a git repository"; return 1; }

  if [ "$(realpath "$path" 2>/dev/null)" = "$(realpath "$root" 2>/dev/null)" ]; then
    message "refusing to remove the main worktree"
    return 1
  fi

  while IFS= read -r p; do
    if [ "$(realpath "$p" 2>/dev/null)" = "$(realpath "$path" 2>/dev/null)" ]; then
      known=1
      break
    fi
  done < <(git -C "$root" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p')
  if [ "$known" != 1 ]; then
    message "not a worktree of this repository: $path"
    return 1
  fi

  # Reject paths outside WORKTREE_ROOT so we never delete arbitrary dirs.
  case "$(realpath "$path" 2>/dev/null || echo "$path")" in
    "$(realpath "$WORKTREE_ROOT" 2>/dev/null || echo "$WORKTREE_ROOT")"/*) ;;
    *) message "refusing path outside $WORKTREE_ROOT"; return 1 ;;
  esac

  # Verify the worktree is clean. Abort if git status fails.
  local status
  status=$(git -C "$path" status --porcelain 2>/dev/null) || {
    message "cannot verify clean status: $path"
    return 1
  }
  if [ -n "$status" ]; then
    message "worktree has uncommitted changes: $path"
    return 1
  fi

  # Close any tmux window pointing at this worktree before removing it.
  session=$(current_session 2>/dev/null || true)
  if [ -n "$session" ]; then
    wid=$(tmux list-windows -t "$session" -F $'#{window_name}\t#{window_id}\t#{pane_current_path}' 2>/dev/null |
      awk -F '\t' -v p="$path" '$3 == p || index($3, p"/") == 1 { print $2; exit }')
    [ -n "$wid" ] && tmux kill-window -t "$wid" 2>/dev/null || true
  fi

  # Prune the MRU so the path does not reappear in the picker.
  # We remove it by writing every line except the removed path.
  if [ -f "$MRU" ]; then
    local tmpdir tmp
    tmpdir=$(dirname "$MRU")
    tmp=$(mktemp "$tmpdir/.mru.XXXXXX" 2>/dev/null) || return 0
    if grep -Fxv "$path" "$MRU" >"$tmp" 2>/dev/null; then
      mv -f "$tmp" "$MRU"
    else
      rm -f "$tmp"
    fi
  fi

  # Fast path: git removes it cleanly.
  local err
  err=$(git -C "$root" worktree remove "$path" 2>&1) || {
    # git refuses to remove any worktree that contains submodules, even when the
    # checkout is clean. Only take the fallback when .gitmodules exists so a
    # permission/lock failure does not silently delete everything.
    if [ -e "$path/.gitmodules" ]; then
      git -C "$path" submodule deinit --all --force >/dev/null 2>&1 || {
        message "could not deinit submodules in $path"
        return 1
      }
      if rm -rf -- "$path"; then
        message "removed $path (branch kept)"
        return 0
      fi
      message "could not remove $path"
      return 1
    fi
    message "$err"
    return 1
  }

  # Remove any leftover directory in case git left an empty shell.
  [ -d "$path" ] && rmdir -- "$path" 2>/dev/null || true
  message "removed $path (branch kept)"
  return 0
}

case "${1:-}" in
  prompt) prompt_new ;;
  new) shift; new_worktree "${1:-}" ;;
  pick) pick_worktree ;;
  list-mru) list_mru ;;
  open-all) open_all_worktrees ;;
  list) list_worktrees ;;
  preview) shift; preview_worktree "${1:-}" ;;
  open|focus) shift; open_worktree "${1:-}" ;;
  remove) shift; remove_worktree "${1:-}" ;;
  *)
    printf 'usage: %s {prompt|new NAME|pick|list-mru|open-all|list|preview PATH|open PATH|remove PATH}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
