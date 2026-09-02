#!/bin/bash
# Keep the bar's notch gap as wide as Alcove's window (it grows while media plays).
BASE=240
STATE="$CONFIG_DIR/.notch_width"
[ "$SENDER" = "media_change" ] && sleep 0.8   # let Alcove finish expanding
W=$("$CONFIG_DIR/helper/alcove_width" 2>/dev/null || echo 0)
TARGET=$BASE
[ "$W" -gt 0 ] && TARGET=$(( W + 32 ))
[ "$TARGET" -lt "$BASE" ] && TARGET=$BASE
[ "$(cat "$STATE" 2>/dev/null)" = "$TARGET" ] && exit 0
sketchybar --animate tanh 15 --bar notch_width=$TARGET && echo "$TARGET" > "$STATE"
