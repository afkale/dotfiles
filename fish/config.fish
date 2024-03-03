starship init fish | source

set -l plugins z

for plugin in $plugins
	if test -f "$__fish_config_dir/plugins/$plugin/$plugin.fish"
		. "$__fish_config_dir/plugins/$plugin/$plugin.fish"
	end
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
