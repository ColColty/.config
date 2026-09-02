#!/bin/bash
# Show the item only while AirPods are the default output device.
OUT=$(system_profiler SPAudioDataType 2>/dev/null | grep -B 20 "Default Output Device: Yes" | grep -E "^\s*[^ ].*:$" | tail -1)
if echo "$OUT" | grep -qi airpods; then
  sketchybar --set "$NAME" drawing=on
else
  sketchybar --set "$NAME" drawing=off popup.drawing=off
fi
