#!/bin/bash
sketchybar --add event aerospace_mode_change
sketchybar --add item mode left \
           --set mode icon.drawing=off \
                      label.font="$FONT:Bold:11.5" label.color=$BLACK \
                      label.padding_left=8 label.padding_right=8 \
                      background.color=$WHITE \
                      drawing=off updates=on \
                      script="$PLUGIN_DIR/mode.sh" \
           --subscribe mode aerospace_mode_change
