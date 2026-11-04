#!/usr/bin/env bash
# worktree.sh — create and manage task worktrees from tmux.
#
#   worktree.sh prompt        ask for a task name, then create and open it (M-t)
#   worktree.sh new NAME      create a worktree and open it
#   worktree.sh pick          fzf picker for existing worktrees (M-C-t)
#   worktree.sh list          TSV "path<TAB>branch<TAB>dirty" for fzf
#   worktree.sh preview PATH   show one worktree's status
#   worktree.sh open PATH      open (or focus) a tmux window for a worktree
#   worktree.sh remove PATH    remove a clean worktree, keeping its branch
#
# Worktrees live in ${WORKTREE_ROOT:-$HOME/worktrees}/<repo>/<branch>, with
# slashes in the branch replaced by dashes in the directory and window name.
# The branch keeps its real name, so typing feat/login creates branch
# feat/login in ~/worktrees/repo/feat-login.
#
# Override the root with WORKTREE_ROOT or `set -g @worktree_root /path`.

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"

ROOT_SETTING=$(tmux show-option -gqv @worktree_root 2>/dev/null || true)
WORKTREE_ROOT="${WORKTREE_ROOT:-${ROOT_SETTING:-$HOME/worktrees}}"

# Print the canonical checkout for the current directory. Using the first
# worktree entry means this also works when called from a linked worktree.
repo_root() {
  git rev-parse --git-dir >/dev/null 2>&1 || return 1
  git worktree list --porcelain 2>/dev/null |
    sed -n 's/^worktree //p' |
    head -n 1
}

current_session() {
  tmux display-message -p '#{session_id}' 2>/dev/null
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

  session=$(current_session) || fail "not running inside tmux"
  [ -n "$session" ] || fail "not running inside tmux"

  # Namespace the window by repository so two repos with the same branch name
  # do not fight over one window.
  repo=$(basename "$(dirname "$path")")
  name=$(slug "$(basename "$path")")
  name=${name//:/_}
  case "$path" in
    "$WORKTREE_ROOT"/*) name="$repo/$name" ;;
    *) name="$repo" ;;
  esac

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

  # Worktrees do not carry ignored files, so copy the common local env files.
  local file
  for file in .env .env.local .env.development.local .envrc; do
    [ -f "$root/$file" ] && cp -p "$root/$file" "$dir/$file"
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

preview_worktree() {
  local path=${1:-}
  [ -n "$path" ] && [ -d "$path" ] || return 0

  printf '\033[38;2;196;167;231m%s\033[0m\n\n' "$path"
  printf 'branch: %s\n' "$(git -C "$path" branch --show-current 2>/dev/null || echo detached)"
  printf 'head:   %s\n\n' "$(git -C "$path" log -1 --oneline 2>/dev/null)"
  git -C "$path" status --short 2>/dev/null | head -n 40
}

pick_worktree() {
  local selection path
  list_worktrees >/dev/null 2>&1 || {
    printf 'not inside a git repository\n'
    hold
    return 1
  }

  selection=$(
    list_worktrees | fzf \
      --delimiter=$'\t' \
      --with-nth=2,3 \
      --cycle \
      --ansi \
      --info=inline \
      --border=rounded \
      --border-label=' worktrees ' \
      --color='fg:#908caa,bg:#191724,hl:#eb6f92,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92' \
      --color='info:#c4a7e7,prompt:#c4a7e7,pointer:#ebbcba,marker:#9ccfd8,spinner:#f6c177' \
      --color='header:#6e6a86,border:#403d52,label:#c4a7e7,selected-bg:#26233a' \
      --header='enter: open · ctrl-x: remove · ctrl-r: reload · * = dirty · esc: cancel' \
      --preview "$SELF preview {1}" \
      --preview-window='right,55%,border-left,wrap' \
      --bind "ctrl-r:reload($SELF list)" \
      --bind "ctrl-x:execute-silent($SELF remove {1})+reload($SELF list)"
  )

  [ -n "$selection" ] || return 0
  path=${selection%%$'\t'*}
  open_worktree "$path"
}

remove_worktree() {
  local path=${1:-} root
  [ -n "$path" ] && [ -d "$path" ] || { message "not a directory: ${path:-}"; return 1; }
  root=$(repo_root) || { message "not inside a git repository"; return 1; }

  if [ "$(realpath "$path")" = "$(realpath "$root")" ]; then
    message "refusing to remove the main worktree"
    return 1
  fi

  if [ -n "$(git -C "$path" status --porcelain 2>/dev/null | head -n 1)" ]; then
    message "worktree has uncommitted changes: $path"
    return 1
  fi

  if ! git -C "$root" worktree remove "$path"; then
    message "could not remove $path"
    return 1
  fi
  message "removed $path (branch kept)"
}

case "${1:-}" in
  prompt) prompt_new ;;
  new) shift; new_worktree "${1:-}" ;;
  pick) pick_worktree ;;
  list) list_worktrees ;;
  preview) shift; preview_worktree "${1:-}" ;;
  open) shift; open_worktree "${1:-}" ;;
  remove) shift; remove_worktree "${1:-}" ;;
  *)
    printf 'usage: %s {prompt|new NAME|pick|list|preview PATH|open PATH|remove PATH}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
