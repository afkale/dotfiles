# Agent instructions (dotfiles)

## Plans

Before implementing a change, write a plan in `docs/plans/` (see its README) and get it
approved through `plannotator annotate <file> --gate`. Do not start implementing until its
`status` is `approved`.

## Domain language

Read `GLOSSARY.md` before changing anything under `nvim/`, `yazi/`, `lazygit/` or
`opencode/`. It defines how this workflow talks about workspaces, tabs, panes, worktrees and
popups; use its vocabulary in code, comments and commit messages.

## Agent skills

### Issue tracker

GitHub issues in `afkale/dotfiles`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles mapped to GitHub labels (`needs-triage`, `needs-info`,
`ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.
