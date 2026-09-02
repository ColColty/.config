#!/bin/bash
case "$SENDER" in
  mouse.entered.global) sketchybar --animate tanh 10 --set "$NAME" drawing=on label="$(date '+%a %d %b')" ;;
  mouse.exited.global)  sketchybar --animate tanh 10 --set "$NAME" drawing=off ;;
  *)                    sketchybar --set "$NAME" label="$(date '+%a %d %b')" ;;
esac
