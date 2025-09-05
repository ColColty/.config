#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
    CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/colors.sh"

# Get current focus mode using the shortcut
FOCUS_MODE=$(shortcuts run "Get Current Focus" 2>/dev/null || echo "")

# Clean up the result (remove any extra whitespace/newlines)
FOCUS_MODE=$(echo "$FOCUS_MODE" | tr -d '\n\r' | xargs)

# Update the sketchybar item based on the focus mode
if [ -z "$FOCUS_MODE" ] || [ "$FOCUS_MODE" = "Off" ] || [ "$FOCUS_MODE" = "off" ]; then
    # No focus mode active - hide the item
    sketchybar --set focus_mode \
        icon="" \
        label="" \
        drawing=off
else
    # Focus mode is active - show the icon
    case "$FOCUS_MODE" in
        "DND"|"Do Not Disturb")
            ICON="􀆺"
            COLOR="$PURPLE"
            ;;
        "Work"|"work")
            ICON="􀉺"
            COLOR="$BLUE"
            ;;
        "Minimalist")
            ICON="􀳾"
            COLOR="$YELLOW"
            ;;
        "Sleep")
            ICON="􀙪"
            COLOR="$BLUE"
            ;;
        "Gaming")
            ICON="􀛹"
            COLOR="$RED"
            ;;
        "Travel")
            ICON="􀼮"
            COLOR="$GREY"
            ;;
        "Rise")
            ICON="􀆲"
            COLOR="$ORANGE"
            ;;
        *)
            # Default focus icon for any other focus mode
            ICON=""
            ;;
    esac
    
    sketchybar --set focus_mode \
        icon="$ICON" \
        icon.color="$COLOR" \
        label="" \
        drawing=on
fi
