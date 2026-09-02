#!/bin/bash
# Centre the focused floating window on its screen, keeping its size.
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"

IFS='|' read -r LAYOUT PID TITLE <<< "$(aerospace list-windows --focused --format '%{window-layout}|%{app-pid}|%{window-title}')"
[ "$LAYOUT" = "floating" ] || exit 0

read -r X Y W H <<< "$("$DIR/screen_frame")"
ESCAPED_TITLE=${TITLE//\"/\\\"}

osascript <<APPLESCRIPT
tell application "System Events"
  tell (first application process whose unix id is $PID)
    set win to missing value
    try
      set win to first window whose name is "$ESCAPED_TITLE"
    end try
    if win is missing value then set win to window 1
    set {w, h} to size of win
    set position of win to {$X + ($W - w) div 2, $Y + ($H - h) div 2}
  end tell
end tell
APPLESCRIPT
