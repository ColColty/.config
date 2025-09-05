#!/bin/bash

# Check if osx-cpu-temp is installed
if ! command -v osx-cpu-temp &> /dev/null; then
    # Try to get temperature via powermetrics (requires sudo)
    if command -v powermetrics &> /dev/null; then
        TEMP=$(sudo powermetrics -n 1 -s thermal 2>/dev/null | grep "CPU die temperature" | awk '{print $4}' | sed 's/°C//')
        if [ -z "$TEMP" ]; then
            TEMP="--"
        fi
    else
        # Fallback: suggest installing osx-cpu-temp
        TEMP="--"
    fi
else
    # Use osx-cpu-temp if available
    TEMP=$(osx-cpu-temp -C 2>/dev/null | sed 's/°C//')
    if [ -z "$TEMP" ]; then
        TEMP="--"
    fi
fi

# Format temperature (round to integer if it's a number)
if [[ "$TEMP" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    TEMP=$(printf "%.0f" "$TEMP")
fi

sketchybar --set $NAME label="${TEMP}°C"