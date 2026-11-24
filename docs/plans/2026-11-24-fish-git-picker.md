---
id: 2026-11-24-fish-git-picker
title: Fish function to pick and checkout a git branch with fzf
status: done            # draft | approved | denied | done
branch: main
ticket: ""
---

## Goal

Add a fish function `gbr` (git branch) that lists local and remote branches with fzf
and checks out the selected one. Complements the git abbreviations added earlier.

## Design

- Function name: `gbr`. Placed in `fish/.config/fish/functions/gbr.fish`.
- Lists branches with `git branch -a --format='%(refname:short)'`, deduplicated, sorted.
- Preview: `git log --oneline --graph --decorate -10 <branch>`.
- On selection, runs `git checkout <branch>` (or `git switch`).
- Handles the case where no branches match (empty selection) gracefully.
- Uses the same FZF_DEFAULT_OPTS already set in config.fish.

## Verification

- `fish -n` on the new file.
- Manual: `gbr` in a git repo, pick a branch, confirm checkout.
- `make doctor` passes.

## Out of scope

- Creating new branches (use `gcb` abbreviation for that).
- Deleting branches.
- Integration with lazygit.
