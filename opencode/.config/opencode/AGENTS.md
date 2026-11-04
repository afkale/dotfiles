# Agent instructions (AGENTS.md)

## Build & test

- Run `shellcheck -x *.sh` for shell scripts.
- Run `bash -n file.sh` for syntax checks.
- Config is stowed: `make stow` after editing files under `opencode/`, `tmux/`, etc.
- Run `make doctor` to verify the setup is healthy.
- `make push` checks everything before pushing.

## Git conventions

- Worktrees go in `~/worktrees/<repo>/<name>`.
- Keep commits atomic and descriptive.
- Do not commit `.env`, `.env.local`, or `.envrc` files.

## Code style

- Shell: POSIX-ish bash, SC2034 is ok for sourced variables.
- Fish: keep it interactive-only; use `abbr` not `alias` for common commands.
- Lua: follow `nvim/` patterns — packer-style plugins via `ale.pack.*`.
- Markdown: wrap at 100 columns in README/docs, keep tables compact.

## Forbidden

- Never write to `/tmp` — use `$TMPDIR` or `/tmp/opencode`.
- No `sudo` in automated scripts.
- Do not modify `~/.ssh/`, `~/.aws/`, `~/.config/gh/` or other credential directories.
