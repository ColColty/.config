#!/bin/bash
# Runs on every focus change (on-focus-changed). Kept minimal: it only does
# work while a window floated via toggle-float.sh is being tracked.
STATE="$HOME/.config/aerospace/.float-return"
# Focus history (newest last, 5 entries) for scratchpad.sh / close.sh, so they
# can hand focus to the previous window BEFORE a floating window goes away.
H="$HOME/.config/aerospace/.focus-history"
if [ -n "$AEROSPACE_WINDOW_ID" ]; then
  { tail -n 4 "$H" 2>/dev/null | grep -vx "$AEROSPACE_WINDOW_ID"; echo "$AEROSPACE_WINDOW_ID"; } >"$H.tmp" && mv "$H.tmp" "$H"
fi
[ -f "$STATE" ] || exit 0
export PATH="/opt/homebrew/bin:$PATH"
read -r FLOAT RETURN < "$STATE"
NOW="${AEROSPACE_WINDOW_ID:-$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)}"
[ -z "$NOW" ] && exit 0
if [ "$NOW" = "$FLOAT" ]; then
  exit 0                                  # focusing the floating window itself: nothing to do
elif aerospace list-windows --all --format '%{window-id}' 2>/dev/null | grep -qx "$FLOAT"; then
  echo "$FLOAT $NOW" > "$STATE"           # still open: remember the latest tiled window as return target
else
  rm -f "$STATE"                          # gone: AeroSpace picked the first tiled window, correct it
  [ "$NOW" != "$RETURN" ] && exec aerospace focus --window-id "$RETURN"
fi
exit 0
