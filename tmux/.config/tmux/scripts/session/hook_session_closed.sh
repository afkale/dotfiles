#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/envs.sh"

main() {
  rm -f "$FZF_SESSION_HISTORY"
}
main
