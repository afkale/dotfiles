# Rose Pine (main) theming: status bar, windows, messages, borders and popups.

# ---------------------------------------------------------------------------
# Palette (rose-pine, main variant)
# ---------------------------------------------------------------------------
set -g @thm_base    "#191724"
set -g @thm_surface "#1f1d2e"
set -g @thm_overlay "#26233a"
set -g @thm_muted   "#6e6a86"
set -g @thm_subtle  "#908caa"
set -g @thm_text    "#e0def4"
set -g @thm_love    "#eb6f92"
set -g @thm_gold    "#f6c177"
set -g @thm_rose    "#ebbcba"
set -g @thm_pine    "#31748f"
set -g @thm_foam    "#9ccfd8"
set -g @thm_iris    "#c4a7e7"
set -g @thm_hl_low  "#21202e"
set -g @thm_hl_med  "#403d52"
set -g @thm_hl_high "#524f67"

# ---------------------------------------------------------------------------
# Icons (Nerd Fonts)
# ---------------------------------------------------------------------------
set -g @logo " "
set -g @icon_calendar ""
set -g @icon_clock ""

# ---------------------------------------------------------------------------
# Status bar
# ---------------------------------------------------------------------------
set -g status-interval 1
set -g status-style "bg=default,fg=#{@thm_subtle}"
set -g status-left-length 60
set -g status-right-length 85

# The logo turns gold while the prefix (M-space) is pressed, and red while
# lock mode is on. The current window follows the session name.
set -g status-left " #[fg=#{?client_prefix,#{@thm_gold},#{?#{==:#{@locked},1},#{@thm_love},#{@thm_iris}}},bold]#{@logo} #[fg=#{@thm_text},bold]#S #[fg=#{@thm_hl_high}]│ #[fg=#{@thm_muted}]#{window_index}:#[fg=#{@thm_iris}]#{window_name}#{?window_zoomed_flag, ,} "

set -g status-right "#[fg=#{@thm_foam}]#($TMUX_SCRIPTS/status.sh battery)#[fg=#{@thm_hl_high}] │ #[fg=#{@thm_gold}]#{@icon_calendar} %a %d %b #[fg=#{@thm_hl_high}]│ #[fg=#{@thm_iris}]#{@icon_clock} %H:%M:%S "

# ---------------------------------------------------------------------------
# Windows
# ---------------------------------------------------------------------------
# Only the current window is shown (in status-left), so the window list itself
# is empty. This keeps the bar symmetric instead of relying on centring.
set -g window-status-separator ""
set -g window-status-format ""
set -g window-status-current-format ""

# ---------------------------------------------------------------------------
# Messages, copy mode and pane borders
# ---------------------------------------------------------------------------
set -g message-style "bg=#26233a,fg=#e0def4"
set -g message-command-style "bg=#26233a,fg=#c4a7e7"
set -g mode-style "bg=#524f67,fg=#e0def4"

set -g pane-border-style "fg=#403d52"
set -g pane-active-border-style "fg=#c4a7e7"
set -g display-panes-colour "#403d52"
set -g display-panes-active-colour "#c4a7e7"
set -g clock-mode-colour "#c4a7e7"

# ---------------------------------------------------------------------------
# Popups
# ---------------------------------------------------------------------------
set -g popup-border-style "fg=#524f67"
set -g popup-border-lines "rounded"
set -g popup-style "bg=#191724,fg=#e0def4"
