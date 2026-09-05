#!/bin/bash
# Hyprland/i3-style scratchpad for AeroSpace.
#   scratchpad.sh toggle      scratchpad on this workspace? hide it : show it here
#                             (also when it was left showing on another workspace)
#   scratchpad.sh send        focused window: add it to the scratchpad (hidden) or,
#                             if it is already a scratchpad window, remove it (back to tiling)
#   scratchpad.sh show [ws]   show the scratchpad windows on workspace ws (default: focused)
#   scratchpad.sh hide
# Hidden windows are parked in workspace "S" (filtered out of the bar).
# Built for latency: one parallel query round, the per-window moves run in
# parallel, and place_window boots while all that happens (see place_window.swift).
export PATH="/opt/homebrew/bin:$PATH"
DIR="$(cd "$(dirname "$0")" && pwd)"
# SCRATCHPAD_STATE / SCRATCHPAD_HIDDEN can override these (used for testing).
SET="${SCRATCHPAD_STATE:-$DIR/.scratchpad}"    # one "window-id|app-pid" line per scratchpad window
RETURN="$SET-return"                           # window to give focus back to on hide
HIDDEN="${SCRATCHPAD_HIDDEN:-S}"
PCT=70

touch "$SET"

# One round trip (both CLI calls in parallel) -> ALL ("id|workspace|pid" lines),
# FOCUSED_WIN, FOCUSED_WS. Also prunes closed windows from the set and adopts
# windows that ended up in S without going through send (a rule, a manual move).
query() {
  exec 3< <(aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-pid}' 2>/dev/null)
  IFS='|' read -r FOCUSED_WIN FOCUSED_WS <<<"$(aerospace list-windows --focused --format '%{window-id}|%{workspace}' 2>/dev/null)"
  ALL=$(cat <&3)
  [ -n "$FOCUSED_WS" ] || FOCUSED_WS=$(aerospace list-workspaces --focused)
  local kept="" id ws pid
  while IFS='|' read -r id pid; do
    [ -n "$id" ] && grep -q "^$id|" <<<"$ALL" && kept="$kept$id|$pid"$'\n'
  done <"$SET"
  while IFS='|' read -r id ws pid; do
    [ "$ws" = "$HIDDEN" ] && ! grep -q "^$id|" <<<"$kept" && kept="$kept$id|$pid"$'\n'
  done <<<"$ALL"
  printf '%s' "$kept" >"$SET"
}
# place_window is launched before anything else so its AppKit startup overlaps
# with the query and the moves; it acts on the lines written to fd 5 later.
start_placer() { exec 5> >("$DIR/place_window" "$PCT"); }
ws_of()   { grep "^$1|" <<<"$ALL" | cut -d'|' -f2; }
members() { cut -d'|' -f1 "$SET"; }
on_ws()   { for id in $(members); do [ "$(ws_of "$id")" = "$1" ] && echo "$id"; done; }   # members on workspace $1

show() { # $1: target workspace (default focused). Expects query() done.
  local target=${1:-$FOCUSED_WS} id pid
  [ -s "$SET" ] || return 0
  if [ -n "$FOCUSED_WIN" ] && ! grep -q "^$FOCUSED_WIN|" "$SET"; then echo "$FOCUSED_WIN" >"$RETURN"; fi
  [ "$target" != "$FOCUSED_WS" ] && aerospace workspace "$target"
  local moving=""
  while IFS='|' read -r id pid; do
    [ -n "$id" ] || continue
    [ "$(ws_of "$id")" = "$target" ] && continue   # already here, leave it as the user has it
    aerospace move-node-to-workspace --focus-follows-window --window-id "$id" "$target" 2>/dev/null &
    moving="$moving$pid|$id"$'\n'
  done <"$SET"
  wait
  printf '%s' "$moving" >&5; exec 5>&-                # placer has been booting since start; go
}

hide() { # Expects query() done.
  local id pid back=""
  exec 5>&- 2>/dev/null                               # placer not needed: EOF makes it exit
  # Give focus back FIRST, while the floating windows are still here. If they
  # left first, AeroSpace would focus the first tiled window and we would then
  # correct it: that is the flash of the wrong app.
  [ -f "$RETURN" ] && read -r back <"$RETURN"; rm -f "$RETURN"
  refocus "$back"
  for id in $(members); do
    [ "$(ws_of "$id")" = "$HIDDEN" ] || aerospace move-node-to-workspace --window-id "$id" "$HIDDEN" 2>/dev/null &
  done
  wait
}

# Focus $1 if it is a live window on the focused workspace and not a scratchpad
# window; otherwise the most recent such window from the focus history.
refocus() {
  local id
  for id in "$1" $(tail -r "$DIR/.focus-history" 2>/dev/null); do
    [ -n "$id" ] && [ "$id" != "$FOCUSED_WIN" ] || continue
    grep -q "^$id|" "$SET" && continue
    [ "$(ws_of "$id")" = "$FOCUSED_WS" ] || continue
    aerospace focus --window-id "$id" 2>/dev/null; return
  done
}

send() {
  exec 3< <(aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-pid}' 2>/dev/null)
  IFS='|' read -r id ws layout pid <<<"$(aerospace list-windows --focused --format '%{window-id}|%{workspace}|%{window-layout}|%{app-pid}' 2>/dev/null)"
  ALL=$(cat <&3); FOCUSED_WIN=$id; FOCUSED_WS=$ws
  [ -n "$id" ] || exit 0
  if grep -q "^$id|" "$SET"; then
    grep -v "^$id|" "$SET" >"$SET.tmp"; mv "$SET.tmp" "$SET"
    aerospace layout tiling --window-id "$id" 2>/dev/null
  else
    echo "$id|$pid" >>"$SET"
    # float now so show() never has to
    [ "$layout" = floating ] || aerospace layout floating --window-id "$id" 2>/dev/null
    refocus ""                                  # hand focus over before the window leaves (no flash)
    aerospace move-node-to-workspace --window-id "$id" "$HIDDEN"
  fi
}

case "$1" in
  toggle) start_placer; query; if [ -n "$(on_ws "$FOCUSED_WS")" ]; then hide; else show; fi ;;
  show)   start_placer; query; show "$2" ;;
  hide)   query; hide ;;
  send)   send ;;
  *)      echo "usage: $0 toggle|send|show [ws]|hide" >&2; exit 1 ;;
esac
