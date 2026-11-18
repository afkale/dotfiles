---
id: 2026-11-18-terminal-ux
title: Terminal UX: popup copy, status bar toggle, agent-manager keys
status: approved
branch: ""
ticket: ""
---

## Goal
Fix three daily friction points: copy mode in the M-1 popup, a key to hide the tmux status bar,
and agent-manager keybindings that feel wrong to the user.

## Files
- `tmux/.config/tmux/scripts/popup.sh`: the M-1 popup currently unbinds every root and prefix key
  and turns the status bar off, so copy mode is unreachable. Keep the status bar off and the
  M-1 detach, and restore the copy-mode keys from `tmux.conf`.
- `tmux/.config/tmux/tmux.conf`: add a toggle for the status bar on a free chord. `M-s` is free
  (checked with `tmux list-keys -T root`). Also keep the popup's copy keys in sync with the
  main copy-mode table.
- agent-manager keybindings: location to be found in step 1. Only `focus_key` and
  `arrow_step_keys` are in `agent-manager settings`, so the bindings probably live in the
  binary or a file under `~/.config/agent-manager/`.

## Order
1. Find where agent-manager defines its keys, and list the current bindings. Nothing changes yet.
   Depends on nothing.
2. Propose the new agent-manager bindings, with the user choosing. Depends on 1.
3. Popup copy mode: reproduce, change `popup.sh` so copy-mode keys work, and check that M-1 still
   detaches. Depends on nothing.
4. Status bar toggle: add `bind -n M-s set -g status` to `tmux.conf`, then run `tmux source` and
   check it. Depends on nothing.
5. Apply the agent-manager bindings through their config, once step 2 is approved. Depends on 2.
6. One commit per file change: popup, status toggle, agent-manager. Depends on 3, 4 and 5.

## Risks
- Popup copy keys could clash with keys that the popup's own shell uses. Mitigation: test `v`, `y`
  and `M-v` inside the popup, and check the shell still gets normal keys.
- A status toggle on `M-s` may conflict with a program that uses it, such as a terminal emulator
  shortcut. Mitigation: test it in the actual terminal and change the chord if needed.
- agent-manager bindings may be compiled into the binary, so they can't be changed in config.
  Mitigation: step 1 reports that before any work starts, and item 3 is then dropped or
  redesigned with the user.

## Test strategy
- Inside the M-1 popup: `M-v` enters copy mode, `v` selects, `y` copies to the clipboard, and
  `M-1` detaches.
- `M-s` toggles the status bar on and off in the main session.
- `tmux source ~/.config/tmux/tmux.conf` gives no errors. `make doctor` still passes.
- agent-manager: each changed binding works, and the old one no longer does.

## Open questions
- Which agent-manager keys to change, and to what. Decide with: you, after step 1 lists the
  current bindings.
- Should the status bar toggle hide the bar in all sessions or only the current one? Decide
  with: you.
