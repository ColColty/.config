#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"
source "$CONFIG_DIR/colors.sh"

# Read state live so overlapping runs always end on the current workspace.
J=$(omniwmctl query workspaces --format json 2>/dev/null) || exit 0
args=()
while IFS=$'\t' read -r ws focused visible count; do
  [ -n "$ws" ] || continue
  if [ "$focused" = "true" ]; then
    args+=(--set "space.$ws" drawing=on background.drawing=on background.color=$WHITE icon.color=$BLACK)
  elif [ "$visible" = "true" ] || [ "${count:-0}" -gt 0 ]; then
    args+=(--set "space.$ws" drawing=on background.drawing=off icon.color=$GREY_5)
  else
    args+=(--set "space.$ws" drawing=off)
  fi
done < <(jq -r '
  [.. | objects | select(has("number") and has("isFocused"))]
  | .[] | [ .number, (.isFocused|tostring), (.isVisible|tostring), (.counts.total // 0) ]
  | @tsv' <<<"$J" 2>/dev/null)
[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
