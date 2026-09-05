#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"
source "$CONFIG_DIR/colors.sh"

# Read state live (not from the event's env) so that if two runs overlap the
# later write always reflects the current workspace. No animation: overlapping
# animations were leaving two workspaces highlighted.
ALL=$(aerospace list-workspaces --all 2>/dev/null)
NONEMPTY=" $(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '\n' ' ') "
FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null)
[ -z "$FOCUSED" ] && FOCUSED="$AEROSPACE_FOCUSED_WORKSPACE"

args=()
for ws in $ALL; do
  [ "$ws" = "S" ] && continue   # scratchpad parking workspace, never shown
  if [ "$ws" = "$FOCUSED" ]; then
    args+=(--set "space.$ws" drawing=on background.drawing=on background.color=$WHITE icon.color=$BLACK)
  elif [[ "$NONEMPTY" == *" $ws "* ]]; then
    args+=(--set "space.$ws" drawing=on background.drawing=off icon.color=$GREY_5)
  else
    args+=(--set "space.$ws" drawing=off)
  fi
done
sketchybar "${args[@]}"
