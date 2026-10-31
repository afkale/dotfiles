#!/usr/bin/env bash
# deps.sh — install the Arch packages the configs expect.
#
# The list is intentionally small: tools referenced directly by the fish,
# tmux, nvim and opencode configs. Language toolchains and optional helpers
# are left to the user.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$ROOT/packages/arch.txt"

if [ ! -r "$LIST" ]; then
  printf 'missing package list: %s\n' "$LIST" >&2
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  printf 'pacman not found; install these with your package manager:\n\n' >&2
  cat "$LIST" >&2
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  pacman -S --needed - <"$LIST"
else
  if ! command -v sudo >/dev/null 2>&1; then
    printf 'sudo not found; run as root or install sudo\n' >&2
    exit 1
  fi
  # shellcheck disable=SC2024 # the redirect reads the repo file, not /root
  sudo pacman -S --needed - <"$LIST"
fi
