.PHONY: setup stow restow unlink update shell check-deps deps doctor push

CFG_DIRS := fish ghostty lazygit nvim tmux wallpapers
STOW_OPTS := -t ~

# setup keeps the pinned submodule commit; use `make update` to move it.
setup: check-deps
	@git submodule update --init --recursive
	@$(MAKE) -s stow
	@echo "Run 'make shell' to set fish as your login shell."

stow:
	@stow $(STOW_OPTS) $(CFG_DIRS)
	@stow --no-folding $(STOW_OPTS) opencode

restow:
	@stow -R $(STOW_OPTS) $(CFG_DIRS)
	@stow -R --no-folding $(STOW_OPTS) opencode

unlink:
	@stow -D $(STOW_OPTS) $(CFG_DIRS)
	@stow -D --no-folding $(STOW_OPTS) opencode

update:
	@git submodule update --init --remote --recursive

shell:
	@chsh -s "$$(command -v fish)"

check-deps:
	@for cmd in git stow fish; do \
		command -v $$cmd >/dev/null 2>&1 \
			|| { echo "missing dependency: $$cmd" >&2; exit 1; }; \
	done

deps:
	@scripts/deps.sh

doctor:
	@scripts/doctor.sh

push:
	@scripts/push.sh
