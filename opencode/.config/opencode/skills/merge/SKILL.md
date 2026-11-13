---
name: merge
description: Commit, rebase, and merge the current branch into its base branch.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

**Arguments:** `$ARGUMENTS`

Check the arguments for flags:

- `--no-verify`, `-n` → pass `--no-verify` to the commit in step 1
- `--keep`, `-k` → accepted for habit, but nothing is deleted either way: worktrees
  belong to agent-manager, which the skill never removes

Strip all flags from arguments. A remaining argument names the base branch.

Finish work on the current branch:

1. Commit all uncommitted changes
2. Rebase onto the base branch
3. Fast-forward the base branch to this branch

## Step 1: Commit

Check for staged, unstaged, and untracked changes with `git status --porcelain`. If
there are changes, stage all of them with `git add -A`, review the staged diff,
and commit. Use lowercase, imperative mood, no conventional commit prefixes.
Skip if the working tree is clean.

## Step 2: Rebase

Resolve the base branch:

1. The argument, when one was given
2. Otherwise `main`, when that branch exists locally
3. Otherwise the repository default, from
   `git symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/`)

Rebase onto the local base branch (do NOT fetch from origin first):

```
git rebase <base-branch>
```

IMPORTANT: Do NOT run `git fetch`. Do NOT rebase onto `origin/<branch>`. Only rebase onto the local branch name (e.g. `git rebase main`, not `git rebase origin/main`).

If conflicts occur:

- BEFORE resolving any conflict, understand what changes were made to each
  conflicting file in the base branch
- For each conflicting file, run `git log -p -n 3 <base-branch> -- <file>` to
  see recent changes to that file in the base branch
- The goal is to preserve BOTH the changes from the base branch AND our branch's
  changes
- After resolving each conflict, stage the file and continue with
  `git rebase --continue`
- If a conflict is too complex or unclear, ask for guidance before proceeding

## Step 3: Merge

The rebase put this branch directly on top of the base, so the merge is always a
fast-forward:

```
git checkout <base-branch>
git merge --ff-only <branch>
git checkout <branch>
```

Report the resulting commit range. Do not delete the branch or the worktree, and
do not touch any agent session: that cleanup belongs to agent-manager (`am`).
