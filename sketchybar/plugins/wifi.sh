#!/bin/bash
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
WIFI_IF=$(networksetup -listallhardwareports 2>/dev/null | awk '/Hardware Port: Wi-Fi/{getline; print $2}')

if [ -z "$IFACE" ]; then
  sketchybar --set "$NAME" icon="$WIFI_DISCONNECTED" icon.color=$RED label="Offline" label.color=$RED label.drawing=on
elif [ "$IFACE" = "$WIFI_IF" ]; then
  sketchybar --set "$NAME" icon="$WIFI_CONNECTED" icon.color=$WHITE label.drawing=off
else
  sketchybar --set "$NAME" icon="$ETHERNET" icon.color=$WHITE label.drawing=off
fi
