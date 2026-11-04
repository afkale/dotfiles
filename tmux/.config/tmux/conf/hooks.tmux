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

# MRU tracking for the M-s session picker. Switching clients is what actually
# changes sessions, so record there (plus new sessions).
# #{session_id} is "$N" — numeric and safe — so there is no injection risk.
set-hook -g client-session-changed "run-shell -b '$PANE_SCRIPT save #{pane_id}'"
set-hook -ag client-session-changed "run-shell -b '$SESSIONS_SCRIPT record-id #{session_id}'"
set-hook -g after-new-session "run-shell -b '$SESSIONS_SCRIPT record-id #{session_id}'"

# Keep the session layout snapshot close to the live state. Appending keeps
# the pane-history hooks above intact.
set-hook -ag after-new-window "run-shell -b '$SESSIONS_SCRIPT save --quiet'"
set-hook -ag after-split-window "run-shell -b '$SESSIONS_SCRIPT save --quiet'"
set-hook -ag after-kill-pane "run-shell -b '$SESSIONS_SCRIPT save --quiet'"
set-hook -ag session-renamed "run-shell -b '$SESSIONS_SCRIPT save --quiet'"
set-hook -ag session-closed "run-shell -b '$SESSIONS_SCRIPT save --quiet'"
set-hook -g client-detached "run-shell -b '$SESSIONS_SCRIPT save --quiet'"
