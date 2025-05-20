install:
	@if ! command -v home-manager > /dev/null; then \
		echo "Installing Nix and Home Manager..."; \
		curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes; \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
		nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager; \
		nix-channel --update; \
		nix-shell '<home-manager>' -A install; \
	fi
	@git submodule init
	@git submodule update --remote --recursive
	@cd dotfiles/nvim && git checkout main
	@sed -i "s#\/home\/afkale#$HOME#" home.nix
	@sed -i "s/afkale/$USER/" home.nix
	@home-manager switch -b backup

