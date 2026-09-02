#!/bin/bash
# Keeps the bar's notch gap as wide as Alcove's window (it grows while media plays).
rm -f "$CONFIG_DIR/.notch_width"   # bar starts at notch_width=240 after a reload
sketchybar --add item notch left \
           --set notch drawing=off updates=on update_freq=3 script="$PLUGIN_DIR/notch.sh" \
           --subscribe notch media_change system_woke
