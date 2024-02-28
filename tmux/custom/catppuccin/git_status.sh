show_git_status() {
    local current_path="#{pane_current_path}"
    local is_repo="#(cd "$current_path" && git rev-parse --is-inside-work-tree 2>/dev/null)"

	local icon="$(get_tmux_option "@catppuccin_git_status_icon" "")"
	local color="$(get_tmux_option "@catppuccin_git_status_color" "$thm_blue")"
	local text="$(get_tmux_option "@catppuccin_git_status_text" "#($HOME/.config/tmux/scripts/git_branch_name.sh $current_path)")"
	local module=$(build_status_module "$index" "$icon" "$color" "$text")
	echo "$module"
}

