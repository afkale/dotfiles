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

### Skill sources

`opencode/.config/opencode/skills/` is a verbatim copy of `mattpocock/skills` @ `abeeaf9`
(all 39). Do not edit those files; resync from upstream and fix the wrapper instead.

### Asking questions

When a skill (or any instruction) tells you to ask the user a question, prefer OpenCode's
`question` tool over printing numbered questions in prose. The tool renders an interactive
picker in the TUI and keeps the conversation structured. Fall back to prose only when the
question needs free-form text or a long explanation that doesn't fit the tool's options.

### Slash commands

The 24 skills upstream marks user-invoked only (`disable-model-invocation: true`) have a
one-line `commands/<id>.md` wrapper, so they run as `/<id>`. The wrapper loads the skill by
ID; the skill stays the source of truth.
