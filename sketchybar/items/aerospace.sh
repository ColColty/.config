#!/usr/bin/env bash
# One item per workspace (number only) plus a single hidden "driver" item that
# refreshes all of them in one sketchybar call per event. Ten scripts per event
# was what made the highlight lag.
sketchybar --add event aerospace_workspace_change

WORKSPACES=""
for _ in 1 2 3 4 5; do
  WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null)
  [ -n "$WORKSPACES" ] && break
  sleep 1
done
[ -z "$WORKSPACES" ] && WORKSPACES=$(seq 1 10)

for ws in $WORKSPACES; do
  sketchybar --add item "space.$ws" left \
             --set "space.$ws" icon="$ws" \
                               icon.font="$FONT:Bold:12.5" \
                               icon.padding_left=8 icon.padding_right=8 \
                               label.drawing=off \
                               padding_left=1 padding_right=1 \
                               background.height=20 background.corner_radius=6 background.drawing=off \
                               drawing=off \
                               click_script="aerospace workspace $ws"
done

sketchybar --add bracket workspaces '/space\..*/' \
           --set workspaces background.color=$ITEM_BG_COLOR background.corner_radius=8 background.height=26 padding_left=0 padding_right=0

sketchybar --add item aerospace_driver left \
           --set aerospace_driver drawing=off updates=on script="$PLUGIN_DIR/aerospace.sh" \
           --subscribe aerospace_driver aerospace_workspace_change front_app_switched system_woke
