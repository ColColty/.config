#!/bin/bash
# alt-q. Same as `aerospace close`, except that for a floating window focus is
# handed to the previous window on this workspace BEFORE closing. Otherwise
# AeroSpace focuses the first tiled window and on-focus-changed.sh corrects it
# a moment later: the flash of the wrong app.
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
exec 3< <(aerospace list-windows --all --format '%{window-id}|%{workspace}' 2>/dev/null)
IFS='|' read -r ID WS LAYOUT <<<"$(aerospace list-windows --focused --format '%{window-id}|%{workspace}|%{window-layout}' 2>/dev/null)"
ALL=$(cat <&3)
[ -n "$ID" ] || exit 0
if [ "$LAYOUT" = floating ]; then
  for prev in $(tail -r "$DIR/.focus-history" 2>/dev/null); do
    [ "$prev" != "$ID" ] && grep -q "^$prev|$WS\$" <<<"$ALL" || continue
    aerospace focus --window-id "$prev" 2>/dev/null; rm -f "$DIR/.float-return"; break
  done
fi
aerospace close --window-id "$ID"
