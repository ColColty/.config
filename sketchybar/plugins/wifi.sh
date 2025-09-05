#!/bin/bash

update() {
  source "$CONFIG_DIR/icons.sh"
  
  # Check if we have any active network connection
  DEFAULT_ROUTE=$(route -n get default 2>/dev/null | grep 'interface:' | awk '{print $2}')
  
  if [ -n "$DEFAULT_ROUTE" ]; then
    # We have an active connection - always show strongest signal
    IP_ADDR=$(ipconfig getifaddr "$DEFAULT_ROUTE" 2>/dev/null)
    ICON="$WIFI_CONNECTED"
    
    # Determine connection type and set appropriate label
    if [[ "$DEFAULT_ROUTE" =~ ^en[0-9]+$ ]]; then
      # Check if it's WiFi or Ethernet
      WIFI_NAME=$(system_profiler SPAirPortDataType 2>/dev/null | grep -A 20 "Current Network Information:" | grep -B 1 "PHY Mode:" | head -1 | awk '{print $1}' | sed 's/:$//')
      
      if [ -n "$WIFI_NAME" ]; then
        LABEL="$WIFI_NAME ($IP_ADDR)"
      else
        # Ethernet connection
        LABEL="Ethernet ($IP_ADDR)"
      fi
    elif [[ "$DEFAULT_ROUTE" == "bridge"* ]] || [[ "$DEFAULT_ROUTE" == "utun"* ]] || [[ "$DEFAULT_ROUTE" == "ipsec"* ]]; then
      # iPhone tethering or other mobile hotspot
      LABEL="iPhone ($IP_ADDR)"
    else
      # Fallback to interface name
      LABEL="$DEFAULT_ROUTE ($IP_ADDR)"
    fi
  else
    # No connection
    ICON="$WIFI_DISCONNECTED"
    LABEL="No Connection"
  fi

  sketchybar --set $NAME icon="$ICON" label="$LABEL"
}

click() {
  CURRENT_WIDTH="$(sketchybar --query $NAME | jq -r .label.width)"

  WIDTH=0
  if [ "$CURRENT_WIDTH" -eq "0" ]; then
    WIDTH=dynamic
  fi

  sketchybar --animate sin 20 --set $NAME label.width="$WIDTH"
}

case "$SENDER" in
  "wifi_change") update
  ;;
  "mouse.clicked") click
  ;;
esac

