---
id: 2026-11-23-productivity-skills
title: Add the missing Matt Pocock productivity skills
status: done            # draft | approved | denied | done
branch: am/<name>        # set when an agent takes the plan
ticket: ""               # optional, e.g. "#123"
---

## Goal
Add the three productivity skills that are missing from `opencode/` (`handoff`, `teach`,
`wait-what`), copied verbatim from upstream `mattpocock/skills` @ `abeeaf9`, so every skill
listed in `productivity/README.md` is available.

## Context
`grill-me` and `to-questionnaire` already exist in
`opencode/.config/opencode/skills/` and are byte-identical to upstream, so they are not changed.
Both carry `disable-model-invocation: true`, which makes them user-invoked only. They may not
appear in the skill list the agent sees, so they look missing even though they are present.

## Files
- `opencode/.config/opencode/skills/handoff/`: `SKILL.md`, `agents/openai.yaml` (new)
- `opencode/.config/opencode/skills/teach/`: `SKILL.md`, `agents/openai.yaml`,
  `GLOSSARY-FORMAT.md`, `LEARNING-RECORD-FORMAT.md`, `MISSION-FORMAT.md`, `RESOURCES-FORMAT.md`
  (new)
- `opencode/.config/opencode/skills/wait-what/`: `SKILL.md`, `agents/openai.yaml` (new)

## Order
1. Copy the three skill folders from upstream `skills/productivity/` into the paths above, with no
   edits. Upstream has no attribution header on companion files, and the local copies don't either.
2. Diff each copied folder against upstream and confirm zero differences.
3. Check that `~/.config/opencode` (a symlink into `dotfiles/`) lists the three new skills. No
   stow run is needed for this, since the whole `skills/` folder is already linked.
4. Run `make doctor`. It already fails on `service.json` (not part of this change), so only check
   that no new failure appears.

## Risks
- `teach` writes files into the current directory as a teaching workspace. It is user-invoked
  only, so the agent cannot start it on its own. Confirm that the flag is kept.
- `wait-what` expects a `GLOSSARY.md`. This repo's glossary is the terminal workflow one. The skill
  still works, but the vocabulary it re-pitches comes from that file.
- `handoff` may mention Claude-specific features. Read it before first use and note any mismatch
  in an issue.

## Test strategy
- `diff -r` of each new folder against `/tmp/opencode/upstream/skills/skills/productivity/<name>`
  shows nothing.
- Each `SKILL.md` has valid frontmatter with `name`, `description` and
  `disable-model-invocation: true`.
- In a new session, the user can run `/handoff`, `/teach` and `/wait-what`.

## Open questions
- Keep `grilling` (model-invoked) next to `grill-me` (user-invoked)? Upstream ships both, so the
  plan keeps both. Decision needed: the user.
- Plans are for changes the agent will implement. My earlier edits to `AGENTS.md`,
  `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md` were made without a plan.
  Decision needed: keep them and record them in a plan, or revert them.
