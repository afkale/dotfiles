---
id: 2026-11-23-all-matt-pocock-skills
title: Install the complete Matt Pocock skill set and its slash commands
status: done            # draft | approved | denied | done
branch: am/<name>      # set when an agent takes the plan
ticket: ""             # optional, e.g. "#123"
---

## Goal

`opencode/.config/opencode/skills/` currently holds 25 of the 39 skills in
`mattpocock/skills` @ `abeeaf9`. Install the 14 missing ones verbatim, and give every
user-invoked skill an OpenCode `commands/<id>.md` wrapper so it is reachable as `/<id>` in
the TUI, the way upstream exposes it as a slash command in Claude Code and Codex.

## Why

`handoff` looked "not installed": the file is present but upstream sets
`disable-model-invocation: true` (Codex: `allow_implicit_invocation: false`), so OpenCode
registers it without advertising it to the model. It loads only when asked for by ID. In
Claude Code and Codex that flag turns the skill into a command; OpenCode has no equivalent
until a `commands/*.md` file exists. The same is true for 23 other skills, so today they
are effectively invisible.

Installing the missing skills also closes the gap between the spec (R9 lists the skill set)
and what is on disk.

## What gets added

**14 skills**, copied verbatim from upstream `abeeaf9` (HEAD `d653911` has the same tree):

| Group | Skills |
|---|---|
| `engineering/` | `code-review`, `pr`, `research`, `wizard` |
| `productivity/` | `writing-for-agents` |
| `misc/` | `git-guardrails-claude-code`, `scaffold-exercises` |
| `in-progress/` | `chief-of-staff`, `claude-handoff`, `loop-me`, `software-factory`, `writing-beats`, `writing-fragments`, `writing-shape` |

The seven `in-progress/` skills are upstream experiments; they are included because the
goal is the complete set, and they are cheap to remove later.

**24 command wrappers**, one per skill marked user-invoked only:

`ask-matt`, `chief-of-staff`, `claude-handoff`, `grill-me`, `grill-with-docs`, `handoff`,
`implement`, `implement-spec`, `improve-codebase-architecture`, `loop-me`, `retro`,
`setup-matt-pocock-skills`, `setup-ts-deep-modules`, `software-factory`, `teach`,
`to-questionnaire`, `to-spec`, `to-tickets`, `triage`, `wait-what`, `wayfinder`,
`writing-beats`, `writing-fragments`, `writing-shape`.

Each wrapper takes its `description` from the skill frontmatter and its body from a fixed
template, so command bodies are one line and the skill stays the single source of truth:

```md title="opencode/.config/opencode/commands/handoff.md"
---
description: Compact the current conversation into a handoff document for another agent to pick up.
---

Load the `handoff` skill with the skill tool, then follow it for: $ARGUMENTS
```

Markdown command templates do not expand `@handoff` (the docs are explicit), so the body
names the skill ID instead of using a mention. The `disable-model-invocation` flags stay
untouched: the point is to keep the model-facing skill list short, as R9 requires.

## Steps

1. `git clone --depth 1` upstream into `$TMPDIR` and `git fetch` `abeeaf9`; copy the 14
   directories with `cp -R`, keeping `agents/` and any `scripts/` or references.
2. Check every copied `SKILL.md` for `name` + `description` frontmatter, absolute home
   paths, and secrets. Drop `git-guardrails-claude-code/`'s hook script only if it would
   execute on import — it is documentation plus a settings snippet, so it stays untouched.
3. Generate the 24 wrappers from the skill frontmatter with a short `python3` loop, so the
   descriptions cannot drift from upstream text by hand.
4. Update `docs/specs/agent-setup-diagnosis.md`: R9 goes from 25 to 39 skills, lists the new
   groups, and the "Skills a mantener" row plus the R9 note record the command wrappers.
5. Note the `commands/` layer in `AGENTS.md` under **Agent skills**, one line.
6. Set this plan to `done`, then commit in two commits: skills, then commands + docs.

## Verification

- `for d in skills/*/; do test -f "$d/SKILL.md" && echo ok; done | wc -l` → 39.
- Every command file has a matching skill directory and a non-empty `description`.
- `/handoff` and `/teach` appear in the TUI command palette after the config reload.
- `skill` tool with `id: code-review` returns the upstream body.
- `make doctor` and `git status` are clean.

## Out of scope

- Enabling any of the newly installed skills for implicit model invocation.
- Running `git-guardrails-claude-code`'s hook installer against `~/.claude` or `.claude/`.
- Changes to the plannotator commands, agents, or `opencode.jsonc`.
