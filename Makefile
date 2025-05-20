install:
	@if ! command -v "home-manager" &> /dev/null; then \
		@bash <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon --yes; \
		@nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager; \
		@nix-channel --update; \
		@nix-shell '<home-manager>' -A install; \
	fi;
	@git submodule init
	@git submodule update --remote --recursive
	@(cd dotfiles/nvim && git checkout main)
	@home-manager switch -b backup
