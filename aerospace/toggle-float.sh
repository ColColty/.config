#!/bin/bash
# Toggle floating for the focused window. When it becomes floating, size it to
# 60% of the screen (width where the app allows it, height always) and centre it.
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
PCT=60

STATE="$DIR/.float-return"
aerospace layout floating tiling || exit 1
IFS='|' read -r ID LAYOUT PID TITLE <<< "$(aerospace list-windows --focused --format '%{window-id}|%{window-layout}|%{app-pid}|%{window-title}')"
if [ "$LAYOUT" != "floating" ]; then rm -f "$STATE"; exit 0; fi

# AeroSpace ignores focus history when a floating window closes and lands on
# the first tiled window. Remember where we came from; on-focus-changed.sh
# restores it once this floating window is gone.
if aerospace focus-back-and-forth 2>/dev/null; then
  PREV=$(aerospace list-windows --focused --format '%{window-id}')
  aerospace focus --window-id "$ID" 2>/dev/null
  [ -n "$PREV" ] && [ "$PREV" != "$ID" ] && echo "$ID $PREV" > "$STATE"
fi

read -r X Y W H <<< "$("$DIR/screen_frame")"
w=$(( W * PCT / 100 )); h=$(( H * PCT / 100 ))
x=$(( X + (W - w) / 2 )); y=$(( Y + (H - h) / 2 ))
ESCAPED_TITLE=${TITLE//\"/\\\"}

osascript <<APPLESCRIPT
tell application "System Events"
  tell (first application process whose unix id is $PID)
    set win to missing value
    try
      set win to first window whose name is "$ESCAPED_TITLE"
    end try
    if win is missing value then set win to window 1
    set size of win to {$w, $h}
    set position of win to {$x, $y}
    -- apps with a minimum width may widen; re-centre using the real size
    set {rw, rh} to size of win
    set position of win to {$X + ($W - rw) div 2, $Y + ($H - rh) div 2}
  end tell
end tell
APPLESCRIPT
