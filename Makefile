.PHONY: setup stow restow unlink update shell check-deps deps doctor push server-doc

CFG_DIRS := fish ghostty lazygit nvim tmux wallpapers yazi
STOW_OPTS := -t ~

# Full setup (desktop: includes ghostty and opencode).
setup: check-deps
	@git submodule update --init --recursive
	@$(MAKE) -s stow
	@echo "Run 'make shell' to set fish as your login shell."

# Server setup (no ghostty, no opencode).
server: check-deps
	@git submodule update --init --recursive
	@stow $(STOW_OPTS) $(filter-out ghostty,$(CFG_DIRS))
	@echo "Run 'make shell' to set fish as your login shell."

stow:
	@stow $(STOW_OPTS) $(CFG_DIRS)
	@stow --no-folding $(STOW_OPTS) opencode

server-stow:
	@stow $(STOW_OPTS) $(filter-out ghostty,$(CFG_DIRS))

restow:
	@stow -R $(STOW_OPTS) $(CFG_DIRS)
	@stow -R --no-folding $(STOW_OPTS) opencode

server-restow:
	@stow -R $(STOW_OPTS) $(filter-out ghostty,$(CFG_DIRS))

unlink:
	@stow -D $(STOW_OPTS) $(CFG_DIRS)
	@stow -D --no-folding $(STOW_OPTS) opencode

server-unlink:
	@stow -D $(STOW_OPTS) $(filter-out ghostty,$(CFG_DIRS))

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

server-deps:
	@DEPS_FAMILY=debian DEPS_MODE=server scripts/deps.sh

doctor:
	@scripts/doctor.sh

server-doc:
	@scripts/doctor.sh --server

push:
	@scripts/push.sh
