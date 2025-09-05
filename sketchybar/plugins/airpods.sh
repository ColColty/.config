#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

# Check if AirPods are the current audio output source
airpods_active() {
    # Find the device name that comes before "Default Output Device: Yes"
    default_output=$(system_profiler SPAudioDataType 2>/dev/null | grep -B 20 "Default Output Device: Yes" | grep "^[[:space:]]*[^[:space:]].*:$" | tail -1)
    
    # Check if the default output device contains "AirPods"
    if echo "$default_output" | grep -iE "airpods" >/dev/null; then
        return 0
    fi
    
    return 1
}

# Get battery level if AirPods are connected
get_airpods_battery() {
    # Try to get battery level from the default output device info
    device_name=$(system_profiler SPAudioDataType 2>/dev/null | grep -B 20 "Default Output Device: Yes" | grep "^[[:space:]]*[^[:space:]].*:$" | tail -1 | sed 's/://g' | xargs)
    
    if [[ "$device_name" =~ [Aa]ir[Pp]ods ]]; then
        # Try to get battery info for this specific device
        battery_info=$(system_profiler SPBluetoothDataType 2>/dev/null | grep -A 20 "$device_name" | grep -i "battery" | head -1)
        if [[ -n "$battery_info" ]]; then
            battery_level=$(echo "$battery_info" | grep -oE '[0-9]+%' | head -1)
            if [[ -n "$battery_level" ]]; then
                echo "$battery_level"
                return
            fi
        fi
    fi
    
    # If no battery info found, just show connected status
    echo ""
}

if airpods_active; then
    battery=$(get_airpods_battery)
    if [[ -n "$battery" ]]; then
        label="$battery"
    else
        label=""
    fi
    
    sketchybar --set airpods \
               icon=$AIRPODS \
               icon.color=$WHITE \
               icon.width=20 \
               label.width=0 \
               padding_left=2 \
               padding_right=2
else
    sketchybar --set airpods \
               icon.width=0 \
               label.width=0 \
               padding_left=0 \
               padding_right=0
fi
