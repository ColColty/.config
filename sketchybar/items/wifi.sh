#!/bin/bash
sketchybar --add item wifi right \
           --set wifi icon.font="$FONT:Regular:13.0" icon.padding_left=4 icon.padding_right=4 label.font="$FONT:Medium:11.5" label.padding_left=0 label.padding_right=4 \
                      label.drawing=off background.drawing=off \
                      update_freq=10 updates=on script="$PLUGIN_DIR/wifi.sh" \
                      click_script="open 'x-apple.systempreferences:com.apple.Network-Settings.extension'" \
           --subscribe wifi wifi_change system_woke
