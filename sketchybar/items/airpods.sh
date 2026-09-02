#!/bin/bash
source "$CONFIG_DIR/icons.sh"
sketchybar --add item airpods right \
           --set airpods icon="$AIRPODS" icon.font="$FONT:Regular:13.0" icon.padding_left=4 icon.padding_right=8 \
                         label.drawing=off background.drawing=off \
                         update_freq=30 updates=on \
                         script="$PLUGIN_DIR/airpods.sh" \
                         click_script="sketchybar --set airpods popup.drawing=toggle" \
                         popup.align=right \
           --subscribe airpods volume_change system_woke

# Popup: noise-control modes run a Shortcut named "AirPods <Mode>" if you have
# created one; otherwise they open Bluetooth settings.
for name in "Noise Cancellation" "Transparency" "Adaptive" "Off"; do
  id="airpods.$(echo "$name" | tr 'A-Z ' 'a-z_')"
  sketchybar --add item "$id" popup.airpods \
             --set "$id" icon.drawing=off label="$name" label.padding_left=12 label.padding_right=12 \
                         background.drawing=off \
                         click_script="$PLUGIN_DIR/airpods_mode.sh '$name'; sketchybar --set airpods popup.drawing=off"
done
sketchybar --add item airpods.settings popup.airpods \
           --set airpods.settings icon.drawing=off label="Bluetooth Settings…" label.padding_left=12 label.padding_right=12 \
                                  label.color=$GREY_4 background.drawing=off \
                                  click_script="open 'x-apple.systempreferences:com.apple.BluetoothSettings'; sketchybar --set airpods popup.drawing=off"
