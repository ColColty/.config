#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"
source "$CONFIG_DIR/colors.sh"
MODE="${AEROSPACE_MODE:-$(aerospace list-modes --current 2>/dev/null)}"
if [ -z "$MODE" ] || [ "$MODE" = "main" ]; then
  sketchybar --set "$NAME" drawing=off
else
  case "$MODE" in
    resize)  COLOR=$ORANGE ;;
    service) COLOR=$PURPLE ;;
    *)       COLOR=$WHITE ;;
  esac
  sketchybar --set "$NAME" drawing=on background.color=$COLOR label="$(echo "$MODE" | tr '[:lower:]' '[:upper:]')"
fi
