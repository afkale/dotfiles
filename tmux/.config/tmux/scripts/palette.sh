#!/usr/bin/env bash
# shellcheck disable=SC2034 # sourced by other scripts, not run standalone
# palette.sh — Rose Pine (main) palette for shell scripts.
#
# Sourced by lib.sh and any script needing ANSI colors. The authoritative
# palette definition is in tmux/conf/status.tmux; change it there first and
# regenerate this file to match.
#
# Each colour is available as:
#   PAL_<NAME>     — ANSI escape sequence for foreground (e.g. $PAL_BASE)
#   PAL_<NAME>_BG  — ANSI escape sequence for background (e.g. $PAL_BASE_BG)
#   PAL_<NAME>_HEX — raw hex value for tmux options / fzf --color (e.g. "#191724")

# Base
PAL_BASE_HEX="#191724"
PAL_BASE=$'\033[38;2;25;23;36m'
PAL_BASE_BG=$'\033[48;2;25;23;36m'

# Surface
PAL_SURFACE_HEX="#1f1d2e"
PAL_SURFACE=$'\033[38;2;31;29;46m'
PAL_SURFACE_BG=$'\033[48;2;31;29;46m'

# Overlay
PAL_OVERLAY_HEX="#26233a"
PAL_OVERLAY=$'\033[38;2;38;35;58m'
PAL_OVERLAY_BG=$'\033[48;2;38;35;58m'

# Muted
PAL_MUTED_HEX="#6e6a86"
PAL_MUTED=$'\033[38;2;110;106;134m'
PAL_MUTED_BG=$'\033[48;2;110;106;134m'

# Subtle
PAL_SUBTLE_HEX="#908caa"
PAL_SUBTLE=$'\033[38;2;144;140;170m'
PAL_SUBTLE_BG=$'\033[48;2;144;140;170m'

# Text
PAL_TEXT_HEX="#e0def4"
PAL_TEXT=$'\033[38;2;224;222;244m'
PAL_TEXT_BG=$'\033[48;2;224;222;244m'

# Love (red)
PAL_LOVE_HEX="#eb6f92"
PAL_LOVE=$'\033[38;2;235;111;146m'
PAL_LOVE_BG=$'\033[48;2;235;111;146m'

# Gold
PAL_GOLD_HEX="#f6c177"
PAL_GOLD=$'\033[38;2;246;193;119m'
PAL_GOLD_BG=$'\033[48;2;246;193;119m'

# Rose
PAL_ROSE_HEX="#ebbcba"
PAL_ROSE=$'\033[38;2;235;188;186m'
PAL_ROSE_BG=$'\033[48;2;235;188;186m'

# Pine (teal)
PAL_PINE_HEX="#31748f"
PAL_PINE=$'\033[38;2;49;116;143m'
PAL_PINE_BG=$'\033[48;2;49;116;143m'

# Foam (cyan)
PAL_FOAM_HEX="#9ccfd8"
PAL_FOAM=$'\033[38;2;156;207;216m'
PAL_FOAM_BG=$'\033[48;2;156;207;216m'

# Iris (purple)
PAL_IRIS_HEX="#c4a7e7"
PAL_IRIS=$'\033[38;2;196;167;231m'
PAL_IRIS_BG=$'\033[48;2;196;167;231m'

# Highlight low
PAL_HL_LOW_HEX="#21202e"
PAL_HL_LOW=$'\033[38;2;33;32;46m'
PAL_HL_LOW_BG=$'\033[48;2;33;32;46m'

# Highlight medium
PAL_HL_MED_HEX="#403d52"
PAL_HL_MED=$'\033[38;2;64;61;82m'
PAL_HL_MED_BG=$'\033[48;2;64;61;82m'

# Highlight high
PAL_HL_HIGH_HEX="#524f67"
PAL_HL_HIGH=$'\033[38;2;82;79;103m'
PAL_HL_HIGH_BG=$'\033[48;2;82;79;103m'

# Reset
PAL_RESET=$'\033[0m'
