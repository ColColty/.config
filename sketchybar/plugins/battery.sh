#!/bin/bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

BATT="$(pmset -g batt)"
PCT="$(echo "$BATT" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
[ -z "$PCT" ] && exit 0
CHARGING="$(echo "$BATT" | grep -c 'AC Power')"
TIME="$(echo "$BATT" | grep -Eo '[0-9]+:[0-9]{2} remaining' | cut -d' ' -f1)"

COLOR=$WHITE
case $PCT in
  100|[8-9][0-9]) ICON=$BATTERY_100 ;;
  [5-7][0-9])     ICON=$BATTERY_75 ;;
  [3-4][0-9])     ICON=$BATTERY_50 ;;
  [1-2][0-9])     ICON=$BATTERY_25 ;;
  *)              ICON=$BATTERY_0 ;;
esac
if [ "$CHARGING" = "0" ]; then
  [ "$PCT" -lt 30 ] && COLOR=$ORANGE
  [ "$PCT" -le 15 ] && COLOR=$RED
fi
[ "$CHARGING" != "0" ] && ICON=$BATTERY_CHARGING

# Icon only above 30%; percentage (and time estimate) below that, percentage while charging
LABEL=""; SHOW=off
if [ "$CHARGING" = "0" ] && [ "$PCT" -lt 30 ]; then
  LABEL="${PCT}%"; [ -n "$TIME" ] && LABEL="${PCT}% · ${TIME}"; SHOW=on
elif [ "$CHARGING" != "0" ] && [ "$PCT" -lt 100 ]; then
  LABEL="${PCT}%"; SHOW=on
fi

sketchybar --set "$NAME" icon="$ICON" icon.color=$COLOR label="$LABEL" label.drawing=$SHOW label.color=$COLOR
