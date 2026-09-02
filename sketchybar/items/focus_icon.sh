#!/bin/bash

focus_mode=(
  script="$PLUGIN_DIR/focus_mode.sh"
  click_script="$PLUGIN_DIR/focus_mode_click.sh toggle"
  icon.font="$FONT:Regular:16.0"
  icon.padding_left=8
  icon.padding_right=4
  label.font="$FONT:Semibold:12.0"
  label.padding_left=2
  label.padding_right=8
  update_freq=5
  updates=on
  popup.align=right
  popup.height=30
)

sketchybar --add item focus_mode right           \
           --set focus_mode "${focus_mode[@]}"   \
           --subscribe focus_mode system_woke front_app_switched