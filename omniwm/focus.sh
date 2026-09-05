#!/bin/bash
# alt+h/j/k/l via Karabiner: OmniWM's directional focus, plus a way out of floating
# windows. From a floating window OmniWM's `focus <dir>` is a no-op (the floating
# window stays focused, or nothing is focused at all), so in that case focus the
# last tiled window of this workspace instead.
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
# NB: --fields is ignored for tsv output, so parse json
focused() { omniwmctl query windows --focused --format json 2>/dev/null | jq -r '[.. | objects | select(has("windowId"))][0] // empty | [.id, .mode] | @tsv'; }
IFS=$'\t' read -r BEFORE_ID BEFORE_MODE <<<"$(focused)"
omniwmctl command focus "$1" >/dev/null 2>&1
IFS=$'\t' read -r AFTER_ID AFTER_MODE <<<"$(focused)"
# focus moved: done. Still on a tiled window: nothing to fix either.
[ "$AFTER_ID" != "$BEFORE_ID" ] && exit 0
[ -n "$AFTER_ID" ] && [ "$AFTER_MODE" != "floating" ] && exit 0
WS=$(omniwmctl query active-workspace --format json 2>/dev/null | jq -r '[.. | objects | select(has("number"))][0].number')
[ -n "$WS" ] || exit 0
TILED=$(omniwmctl query windows --workspace "$WS" --format json 2>/dev/null | jq -r '[.. | objects | select(has("windowId")) | select(.mode=="tiling")] | .[].id')
[ -n "$TILED" ] || exit 0
LAST=$(cat "$DIR/.state/last-focus-$WS" 2>/dev/null)
grep -qx "$LAST" <<<"$TILED" || LAST=$(head -1 <<<"$TILED")
omniwmctl window focus "$LAST" >/dev/null 2>&1
