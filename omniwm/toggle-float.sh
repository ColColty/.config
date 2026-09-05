#!/bin/bash
# Option+Shift+F via Karabiner. Toggle floating; when the window becomes floating,
# size it to 70% of the screen and centre it (what toggle-float.sh did under AeroSpace).
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
omniwmctl command toggle-focused-window-floating || exit 1
sleep 0.05
IFS='|' read -r PID WID MODE <<<"$(omniwmctl query windows --focused --format json 2>/dev/null | jq -r '[.. | objects | select(has("windowId"))][0] // empty | "\(.pid)|\(.windowId)|\(.mode)"')"
if [ -n "$PID" ] && [ "$MODE" = floating ]; then
  echo "$PID|$WID" | "$DIR/place_window" 70 2>>/tmp/omniwm-toggle-float.log
  echo "$(date '+%H:%M:%S') pid=$PID wid=$WID mode=$MODE place_window exit=$? parent=$(ps -o comm= -p $PPID)" >>/tmp/omniwm-toggle-float.log
else
  echo "$(date '+%H:%M:%S') pid=$PID wid=$WID mode=$MODE (no placement)" >>/tmp/omniwm-toggle-float.log
fi
exit 0
