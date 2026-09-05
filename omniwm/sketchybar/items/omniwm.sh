#!/usr/bin/env bash
# Workspace items driven by OmniWM. One item per workspace plus a hidden driver
# item that refreshes all of them in one sketchybar call per event. Events come
# from a long-lived `omniwmctl watch` that fires the custom omniwm_change event.
export PATH="/opt/homebrew/bin:$PATH"
sketchybar --add event omniwm_change

WORKSPACES=""
for _ in 1 2 3 4 5; do
  WORKSPACES=$(omniwmctl query workspaces --format json 2>/dev/null \
    | jq -r '[.. | objects | select(has("number"))] | sort_by(.number) | .[].number' 2>/dev/null | tr '\n' ' ')
  [ -n "${WORKSPACES// /}" ] && break
  sleep 1
done
[ -z "${WORKSPACES// /}" ] && WORKSPACES=$(seq 1 10)

for ws in $WORKSPACES; do
  sketchybar --add item "space.$ws" left \
             --set "space.$ws" icon="$ws" \
                               icon.font="$FONT:Bold:12.5" \
                               icon.padding_left=8 icon.padding_right=8 \
                               label.drawing=off \
                               padding_left=1 padding_right=1 \
                               background.height=20 background.corner_radius=6 background.drawing=off \
                               drawing=off \
                               click_script="omniwmctl command switch-workspace $ws"
done

sketchybar --add bracket workspaces '/space\..*/' \
           --set workspaces background.color=$ITEM_BG_COLOR background.corner_radius=8 background.height=26 padding_left=0 padding_right=0

sketchybar --add item omniwm_driver left \
           --set omniwm_driver drawing=off updates=on script="$PLUGIN_DIR/omniwm.sh" \
           --subscribe omniwm_driver omniwm_change front_app_switched system_woke

# One watcher per bar: it reconnects by itself when OmniWM restarts.
pkill -f 'omniwmctl watch .*omniwm_change' 2>/dev/null
(nohup omniwmctl watch active-workspace,windows-changed,focused-monitor,workspace-bar --no-send-initial --reconnect \
      --exec sketchybar --trigger omniwm_change >/dev/null 2>&1 &)
