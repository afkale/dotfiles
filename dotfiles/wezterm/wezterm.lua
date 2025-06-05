-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Config color scheme to rose-pine-moon
-- local theme = wezterm.plugin.require("https://github.com/neapsix/wezterm").moon
-- config.colors = theme.colors()
config.color_scheme = "Tokyo Night"

config.window_decorations = "NONE"
config.window_background_opacity = 0.80
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.7 }

-- Font configuration
config.font_size = 16
config.freetype_load_flags = "NO_HINTING"
config.font = wezterm.font_with_fallback {
	"Cascadia Code",
	"Share Tech Mono",
	"Input Mono",
	"Symbols Nerd Font Mono",
}

-- default is true, has more "native" look
config.use_fancy_tab_bar = false

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- I don't like putting anything at the ege if I can help it.
config.enable_scroll_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

config.keys = {
	{
		key = 'P',
		mods = 'CTRL',
		action = wezterm.action.ActivateCommandPalette,
	},
	{
		label = 'Lazygit',
		key = 'g',
		mods = 'ALT',
		action = wezterm.action.SplitPane {
			direction = 'Down',
			command = { args = { 'lazygit' } },
			size = { Percent = 95 },
		},
	},
	{
		label = 'Btop',
		key = 'b',
		mods = 'ALT',
		action = wezterm.action.SplitPane {
			direction = 'Down',
			command = { args = { 'btop' } },
			size = { Percent = 95 },
		},
	},
	{
		label = 'Btop',
		key = 'd',
		mods = 'ALT',
		action = wezterm.action.SplitPane {
			direction = 'Down',
			command = { args = { 'sudo', 'ncdu', '/' } },
			size = { Percent = 95 },
		},
	},
}

config.tab_bar_at_bottom = true
config.freetype_load_target = "HorizontalLcd"

-- and finally, return the configuration to wezterm
return config
