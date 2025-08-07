{ config, pkgs, ... }:

{
	# Home Manager needs a bit of information about you and the paths it should
	# manage.
	home.username = "afkale";
	home.homeDirectory = "/home/afkale";

	# This value determines the Home Manager release that your configuration is
	# compatible with. This helps avoid breakage when a new Home Manager release
	# introduces backwards incompatible changes.
	#
	# You should not change this value, even if you update Home Manager. If you do
	# want to update the value, then make sure to first check the Home Manager
	# release notes.
	home.stateVersion = "25.05"; # Please read the comment before changing.

	# The home.packages option allows you to install Nix packages into your
	# environment.
	home.packages =  with pkgs; [
		# Dependencies
		gcc
		binutils
		gnumake
		pkg-config
		cmake
		perl
		# Tools
		neovim
		git
		lazygit
		ncdu
		btop

		# Shell configs
		fish
		atuin
		bat
		carapace
		starship

		# Search tools
		lsd
		fzf
		fd
		ripgrep
		zoxide
		silver-searcher
		universal-ctags

		# LSP Packages
		lua-language-server
		bash-language-server
		angular-language-server
		vscode-langservers-extracted
		dockerfile-language-server-nodejs
		# # python
		ruff
		pyright

		# # rust
		rustc
		cargo
		# Utilities
		python312Packages.ipython
	];

	# Home Manager is pretty good at managing dotfiles. The primary way to manage
	# plain files is through 'home.file'.
	home.file = {
		".config/atuin".source = ./dotfiles/atuin;
		".config/wezterm".source = ./dotfiles/wezterm;
		".config/nvim".source = ./dotfiles/nvim;
		".config/starship.toml".source = ./dotfiles/starship.toml;
		# # Building this configuration will create a copy of 'dotfiles/screenrc' in
		# # the Nix store. Activating the configuration will then make '~/.screenrc' a
		# # symlink to the Nix store copy.
		# ".screenrc".source = dotfiles/screenrc;

		# # You can also set the file content immediately.
		# ".gradle/gradle.properties".text = ''
		#   org.gradle.console=verbose
		#   org.gradle.daemon.idletimeout=3600000
		# '';
	};

	# Home Manager can also manage your environment variables through
	# 'home.sessionVariables'. These will be explicitly sourced when using a
	# shell provided by Home Manager. If you don't want to manage your shell
	# through Home Manager then you have to manually source 'hm-session-vars.sh'
	# located at either
	#
	#  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
	#
	# or
	#
	#  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
	#
	# or
	#
	#  /etc/profiles/per-user/alejandro-rubiooliva/etc/profile.d/hm-session-vars.sh
	#
	home.sessionVariables = {
		EDITOR = "nvim";
	};

	# Let Home Manager install and manage itself.
	programs.home-manager.enable = true;
	programs.fish = {
		enable = true;

		interactiveShellInit = ''
			# TokyoNight Color Palette
			set -l foreground c8d3f5
			set -l selection 2d3f76
			set -l comment 636da6
			set -l red ff757f
			set -l orange ff966c
			set -l yellow ffc777
			set -l green c3e88d
			set -l purple fca7ea
			set -l cyan 86e1fc
			set -l pink c099ff

			# Syntax Highlighting Colors
			set -g fish_color_normal $foreground
			set -g fish_color_command $cyan
			set -g fish_color_keyword $pink
			set -g fish_color_quote $yellow
			set -g fish_color_redirection $foreground
			set -g fish_color_end $orange
			set -g fish_color_option $pink
			set -g fish_color_error $red
			set -g fish_color_param $purple
			set -g fish_color_comment $comment
			set -g fish_color_selection --background=$selection
			set -g fish_color_search_match --background=$selection
			set -g fish_color_operator $green
			set -g fish_color_escape $pink
			set -g fish_color_autosuggestion $comment

			# Completion Pager Colors
			set -g fish_pager_color_progress $comment
			set -g fish_pager_color_prefix $cyan
			set -g fish_pager_color_completion $foreground
			set -g fish_pager_color_description $comment
			set -g fish_pager_color_selected_background --background=$selection

			# setup vi_key_bindings
			fish_vi_key_bindings

			# Set greeting to empty
			set fish_greeting
			set -Ux EDITOR nvim
			set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

			if status is-interactive
					atuin init fish | source
					carapace _carapace | source
					zoxide init fish | source
					starship init fish | source
			end
		'';

		functions = {
			cat = {
				wraps = "bat -n";
				description = "alias cat=bat -n";
				body = "bat -n \$argv";
			};

			l = {
				wraps = "lsd";
				description = "alias l=lsd";
				body = "lsd \$argv";
			};

			la = {
				wraps = "lsd -a";
				description = "alias la=lsd -a";
				body = "lsd -a \$argv";
			};

			lla = {
				wraps = "lsd -la";
				description = "alias lla=lsd -la";
				body = "lsd -la \$argv";
			};

			ls = {
				wraps = "lsd";
				description = "alias ls=lsd";
				body = "lsd \$argv";
			};

			tb = {
				wraps = "toolbox enter arch-toolbox-latest";
				description = "alias tb=toolbox enter arch-toolbox-latest";
				body = "toolbox enter arch-toolbox-latest \$argv";
			};

			tree = {
				wraps = "lsd --tree";
				description = "alias tree=lsd --tree";
				body = "lsd --tree \$argv";
			};

			venv = {
				wraps = "source .venv/bin/activate.fish";
				description = "alias venv=source .venv/bin/activate.fish";
				body = "source .venv/bin/activate.fish \$argv";
			};
		};
	};
}
