#!/bin/bash
sketchybar --add item clock right \
           --set clock icon.drawing=off \
                       label.font="$FONT:Semibold:12.5" label.padding_left=8 label.padding_right=6 background.drawing=off \
                       update_freq=10 script="$PLUGIN_DIR/clock.sh" click_script="$PLUGIN_DIR/zen.sh" \
           --subscribe clock system_woke
