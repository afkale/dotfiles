# Agent instructions (AGENTS.md)

## Build & test

- Run `shellcheck -x *.sh` for shell scripts.
- Run `bash -n file.sh` for syntax checks.
- Config is stowed: `make stow` after editing files under `opencode/`, `nvim/`, etc.
- Run `make doctor` to verify the setup is healthy.
- `make push` only checks that submodules are pushed before the parent. Run
  `make doctor` and `shellcheck -x` yourself before pushing.

## Git conventions

- Worktrees are managed by agent-manager. Do not create them by hand.
- Keep commits atomic and descriptive.
- Do not commit `.env`, `.env.local`, or `.envrc` files.

## Agent Manager

- **Parallel agents**: always set `worktree: true` when calling
  `create_session` — without it, agents share the checkout and overwrite
  each other's changes.
- **Branch prefix**: agent-manager creates branches prefixed `am/`
  (e.g. `am/ticket-13-history`).
- **Commit with `--no-verify`**: the pre-commit hook errors with
  `prek: not found`, so skip hooks on agent commits.
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
- Lua: follow `nvim/` patterns — packer-style plugins via `ale.pack.*`.
- Markdown: wrap at 100 columns in README/docs, keep tables compact.

## Forbidden

- Never write to `/tmp` — use `$TMPDIR` or `/tmp/opencode`.
- No `sudo` in automated scripts.
- Do not modify `~/.ssh/`, `~/.aws/`, `~/.config/gh/` or other credential directories.
