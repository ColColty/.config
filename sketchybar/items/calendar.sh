#!/bin/bash
# Date sits at the left end of the right-hand pill, shown only while the mouse is over the bar.
sketchybar --add item calendar right \
           --set calendar icon.drawing=off \
                          label.font="$FONT:Medium:12.5" label.padding_left=10 label.padding_right=4 padding_left=0 padding_right=0 \
                          drawing=off updates=on \
                          update_freq=60 script="$PLUGIN_DIR/calendar.sh" click_script="open -a Calendar" \
           --subscribe calendar system_woke mouse.entered.global mouse.exited.global
