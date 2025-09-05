#!/bin/bash

source "$CONFIG_DIR/icons.sh"

airpods=(
  padding_right=7
  icon="$AIRPODS"
  script="$PLUGIN_DIR/airpods.sh"
  update_freq=3
)

sketchybar --add item airpods right \
           --set airpods "${airpods[@]}" \
           --subscribe airpods volume_change
