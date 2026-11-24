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

### Slash commands

The 24 skills upstream marks user-invoked only (`disable-model-invocation: true`) have a
one-line `commands/<id>.md` wrapper, so they run as `/<id>`. The wrapper loads the skill by
ID; the skill stays the source of truth.
