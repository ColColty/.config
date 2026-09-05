#!/bin/bash
# Option+M via Karabiner. Centre the focused floating window, keeping its size.
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
IFS='|' read -r PID WID MODE <<<"$(omniwmctl query windows --focused --format json 2>/dev/null | jq -r '[.. | objects | select(has("windowId"))][0] // empty | "\(.pid)|\(.windowId)|\(.mode)"')"
[ -n "$PID" ] && [ "$MODE" = floating ] && echo "$PID|$WID" | "$DIR/place_window" 0
exit 0
