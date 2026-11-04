# Review checklist

Run these against the current diff or branch:

- [ ] `bash -n` passes for all changed shell scripts
- [ ] `shellcheck -x` passes for all changed shell scripts
- [ ] `make doctor` passes (config, stow links, syntax)
- [ ] No secret paths or credentials in the diff
- [ ] Changed tmux config loads cleanly (`tmux -f tmux.conf new-session -d`)
- [ ] New pickers handle empty state (no panes/sessions/worktrees)
- [ ] MRU history never blocks on nonexistent files
- [ ] No `eval`, no unquoted `$SHELL_VAR` expansions in shell scripts
- [ ] Fish abbreviations don't shadow builtins
