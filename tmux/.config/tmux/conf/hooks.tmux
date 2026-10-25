# MRU tracking for the M-d picker.
#
# #{pane_id} is expanded when the hook fires, so the script does not need a
# "current client" (works for key bindings, mouse, and popups alike).

set-hook -g after-select-pane "run-shell -b '$PANE_SCRIPT save #{pane_id}'"
set-hook -g after-select-window "run-shell -b '$PANE_SCRIPT save #{pane_id}'"
set-hook -g after-new-window "run-shell -b '$PANE_SCRIPT save #{pane_id}'"
set-hook -g after-split-window "run-shell -b '$PANE_SCRIPT save #{pane_id}'"
set-hook -g client-session-changed "run-shell -b '$PANE_SCRIPT save #{pane_id}'"

# Forget panes that no longer exist, keep the rest of the order intact.
set-hook -g after-kill-pane "run-shell -b '$PANE_SCRIPT prune'"
set-hook -g window-unlinked "run-shell -b '$PANE_SCRIPT prune'"
set-hook -g session-closed "run-shell -b '$PANE_SCRIPT prune'"
