#!/bin/sh
# Status bar helpers. Output is embedded in tmux formats, so keep it plain text.

battery() {
  for dir in /sys/class/power_supply/BAT*; do
    [ -r "$dir/capacity" ] || continue

    read -r capacity < "$dir/capacity" 2>/dev/null || continue
    read -r state < "$dir/status" 2>/dev/null || state=Unknown

    case "$capacity" in
      ''|*[!0-9]*) continue ;;
    esac

    if [ "$state" = "Charging" ]; then
      icon=""          # bolt
    elif [ "$capacity" -ge 90 ]; then
      icon=""          # full
    elif [ "$capacity" -ge 70 ]; then
      icon=""          # three quarters
    elif [ "$capacity" -ge 45 ]; then
      icon=""          # half
    elif [ "$capacity" -ge 20 ]; then
      icon=""          # quarter
    else
      icon=""          # empty
    fi

    printf '%s %s%%\n' "$icon" "$capacity"
    return 0
  done
}

case "${1:-}" in
  battery) battery ;;
  *) echo "usage: ${0##*/} battery" >&2; exit 2 ;;
esac
