---
id: 2026-11-23-restore-engineering-skills
title: Restore ask-matt, implement, implement-spec and retro
status: done            # draft | approved | denied | done
branch: am/<name>        # set when an agent takes the plan
ticket: ""               # optional, e.g. "#123"
---

## Goal
Restore four Matt Pocock skills that commit `99e7fe2` removed, copied verbatim from upstream
`mattpocock/skills` @ `abeeaf9`, and update the skill list in the spec to match.

## Context
Commit `99e7fe2` ("keep only Matt Pocock's engineering skills") deleted `ask-matt`, `implement`,
`implement-spec` and `retro`. The spec `docs/specs/agent-setup-diagnosis.md` (R9, §6) lists 18
skills to keep, and these four are not among them. The owner has now asked to restore them, so
the spec's R9 and §6 must change to match.

The other 18 skills already match upstream (checked by `diff -r`).

## Files
- `opencode/.config/opencode/skills/ask-matt/`: `SKILL.md`, `PHASE-BOUNDARIES.md`,
  `agents/openai.yaml` (new)
- `opencode/.config/opencode/skills/implement/`: `SKILL.md`, `agents/openai.yaml` (new)
- `opencode/.config/opencode/skills/implement-spec/`: `SKILL.md`, `agents/openai.yaml` (new)
- `opencode/.config/opencode/skills/retro/`: `SKILL.md`, `agents/openai.yaml` (new)
- `docs/specs/agent-setup-diagnosis.md`: R9 list goes from 18 to 22 skills, and §6 "Skills a
  mantener" is updated the same way.

## Order
1. Copy the four folders from upstream `skills/engineering/` (or `skills/misc/` if the path differs
   when copying) into the paths above, with no edits.
2. Diff each folder against upstream and confirm zero differences.
3. Update R9 and §6 of the spec, counting the skills again from the folders on disk.
4. Run `make doctor`. It already fails on `service.json` (not part of this change), so only check
   that no new failure appears.

## Risks
- `implement` and `implement-spec` call `/tdd` and `/code-review`. The local `tdd` is present; the
  local `code-review` is not restored by this plan. Confirm that `implement` does not depend on it
  before first use, and flag it if it does.
- `ask-matt` is a router over the user-invoked skills. Its list must match the skills on disk. If
  any are missing, it will point at a skill that does not exist.
- The spec was previously a deliberate decision, not an oversight. Changing R9 and §6 must record
  that the owner reversed it.

## Test strategy
- `diff -r` of each new folder against upstream shows nothing.
- Each `SKILL.md` has valid frontmatter with `name`, `description`.
- Count the folders under `opencode/.config/opencode/skills/` and check that the spec's R9 number
  matches.

## Open questions
- Restoring `code-review` is not in this plan. Decision needed: whether `implement` should wait for
  it, or whether it should be restored in a follow-up plan.
