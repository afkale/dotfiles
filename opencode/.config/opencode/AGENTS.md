# Agent instructions (AGENTS.md)

## Build & test

- Run `shellcheck -x *.sh` for shell scripts.
- Run `bash -n file.sh` for syntax checks.
- Config is stowed: `make stow` after editing files under `opencode/`, `nvim/`, etc.
- Run `make doctor` to verify the setup is healthy.
- Hooks run through prek (`prek install` once per clone). pre-commit scans for
  secrets with gitleaks. pre-push runs `shellcheck` and `make doctor`.
- `make push` only checks that submodules are pushed before the parent.

## Git conventions

- Worktrees are managed by agent-manager. Do not create them by hand.
- Keep commits atomic and descriptive.
- Do not commit `.env`, `.env.local`, or `.envrc` files.

## Agent skills

### Presenting information

Every response must start with a one- or two-line **TL;DR** in bold that states the
outcome or the ask. Details follow only after that line, and only as much as the task
requires.

Visual hierarchy rules:

- **Bold** the key point or decision; leave supporting detail in plain text.
- One idea per paragraph. Break long explanations into short paragraphs or bullets.
- Indent secondary detail under the point it supports; do not flatten everything to
  the same level.
- Prefer bullets over tables. Tables only when comparing three or more items on the
  same axes; never more than four columns.
- Avoid deep nesting (max two levels). If a third level is needed, split into a
  separate section.
- Code blocks only for code the user will copy or run. Inline backticks for names,
  paths, and commands mentioned in prose.
- Do not repeat the user's question back to them. Answer it.

### Asking questions

When a skill (or any instruction) tells you to ask the user a question, prefer OpenCode's
`question` tool over printing numbered questions in prose. The tool renders an interactive
picker in the TUI and keeps the conversation structured. Fall back to prose only when the
question needs free-form text or a long explanation that doesn't fit the tool's options.

## Agent Manager

- **Parallel agents**: always set `worktree: true` when calling
  `create_session` — without it, agents share the checkout and overwrite
  each other's changes.
- **Branch prefix**: agent-manager creates branches prefixed `am/`
  (e.g. `am/ticket-13-history`).
- **Archive finished sessions**: call `archive_session` after an agent
  finishes to keep the session list clean. Agent Manager does not do
  this automatically.
- **Merge into `main` from a different worktree**: `main` has its own
  checkout, so you cannot `git checkout main` from another worktree.
  Instead use `git fetch <main-worktree-path> main` + `git merge --ff-only FETCH_HEAD`,
  or merge `FETCH_HEAD` with `--no-ff` directly on the main worktree.

## Code style

- Shell: POSIX-ish bash, SC2034 is ok for sourced variables.
- Fish: keep it interactive-only; use `abbr` not `alias` for common commands.
- Lua: follow `nvim/` patterns — plugins are declared with `vim.pack.add` and
  configured per topic under `lua/ale/pack/`.
- Markdown: wrap at 100 columns in README/docs, keep tables compact.

## Forbidden

- Never write to `/tmp` — use `$TMPDIR` or `/tmp/opencode`.
- No `sudo` in automated scripts.
- Do not modify `~/.ssh/`, `~/.aws/`, `~/.config/gh/` or other credential directories.
