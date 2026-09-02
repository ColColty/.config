#!/bin/bash
sketchybar --add item battery right \
           --set battery icon.font="$FONT:Regular:14.0" icon.padding_left=4 icon.padding_right=2 label.font="$FONT:Medium:11.5" label.padding_left=0 label.padding_right=4 label.drawing=off \
                         background.drawing=off update_freq=60 updates=on \
                         script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery power_source_change system_woke
