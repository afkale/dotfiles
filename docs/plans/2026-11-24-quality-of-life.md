---
id: 2026-11-24-quality-of-life
title: Quality-of-life features for tmux, fish and repo tooling
status: done            # draft | approved | denied | done
branch: main
ticket: ""
---

## Goal

Ship five small, independent improvements the user picked from the codebase review:

1. **tmux resize bindings** — prefix + H/J/K/L resize panes.
2. **tmux git branch in status** — show the current branch in the right status segment.
3. **CI** — GitHub Actions running `shellcheck -x` and `make doctor`.
4. **Make: test target** — `make test` runs `popup_test.sh` and the doctor syntax checks.
5. **fish: git abbreviations** — `gs`, `gc`, `gp`, `gl`, `gd`, `gco`, `gcb`.

Session restore is deliberately excluded: it is a larger, stateful feature that needs its
own spec and plan.

## Changes

### 1. tmux resize bindings

In `tmux/.config/tmux/tmux.conf`, under the Layout (prefix only) section, add:

```
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5
```

`-r` allows repeat. Keep the existing `h/j/k/l` select-pane bindings untouched.

### 2. tmux git branch in status

Right status segment becomes:

```
set -g status-right "#[fg=#9ccfd8]#{?window_zoomed_flag,zoomed ,}#[fg=#6e6a86]#{pane_current_command} #[fg=#c4a7e7]#(git -C '#{pane_current_path}' rev-parse --abbrev-ref HEAD 2>/dev/null)"
```

The `#(...)` runs every `status-interval` (5s). Guard with `2>/dev/null` so non-git
directories show nothing. Note: this runs git in the pane's directory on every refresh;
acceptable for a personal setup.

### 3. CI

New file `.github/workflows/ci.yml`:

- Trigger on push and pull_request to `main`.
- Jobs: `shellcheck` (runs `shellcheck -x` over the same files the pre-push hook does)
  and `doctor` (runs `make doctor` on ubuntu-latest, with the tools installed via
  `scripts/deps.sh` or apt where needed).
- Keep it simple: ubuntu-latest, install git/stow/fish/tmux/fzf/fd/rg/bat on apt.

### 4. Make: test target

Add to `Makefile`:

```
test:
    @bash tmux/.config/tmux/scripts/popup_test.sh
```

And add `test` to `.PHONY`.

### 5. fish git abbreviations

In `fish/.config/fish/config.fish`, inside the interactive block:

```
abbr --add gs  'git status'
abbr --add gc  'git commit'
abbr --add gp  'git push'
abbr --add gl  'git log --oneline --graph --decorate -20'
abbr --add gd  'git diff'
abbr --add gco 'git checkout'
abbr --add gcb 'git checkout -b'
```

Use `abbr` (not `alias`) per the repo convention.

## Verification

- `bash -n` and `shellcheck -x` on changed scripts.
- `make doctor` passes.
- `make test` passes.
- tmux config loads (`tmux -L dotfiles-doctor -f ... new-session -d`).
- CI workflow is valid YAML.

## Out of scope

- Session restore (separate spec/plan).
- Changes to nvim (submodule).
- Any change to opencode config beyond what's already committed.
