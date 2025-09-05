#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
    CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/colors.sh"

# Handle different click actions
if [ "$1" = "toggle" ]; then
    # Get current focus mode
    CURRENT_MODE=$(shortcuts run "Get Current Focus" 2>/dev/null || echo "Off")
    
    # Remove existing popup items
    sketchybar --remove '/focus_mode_.*/' 2>/dev/null
    
    # Define available focus modes
    FOCUS_MODES=("Off" "DND" "Work" "Minimalist" "Sleep" "Gaming" "Travel" "Rise")
    
    # Create popup items
    for i in "${!FOCUS_MODES[@]}"; do
        mode="${FOCUS_MODES[$i]}"
        
        # Set icon and color
        # Focus mode is active - show the icon
        case "$FOCUS_MODE" in
            "DND"|"Do Not Disturb")
                icon="􀆺"
                color="$PURPLE"
                ;;
            "Work"|"work")
                icon="􀉺"
                color="$BLUE"
                ;;
            "Minimalist")
                icon="􀳾"
                color="$YELLOW"
                ;;
            "Sleep")
                icon="􀙪"
                color="$BLUE"
                ;;
            "Gaming")
                icon="􀛹"
                color="$RED"
                ;;
            "Travel")
                icon="􀼮"
                color="$GREY"
                ;;
            "Rise")
                icon="􀆲"
                color="$ORANGE"
                ;;
            *)
                # Default focus icon for any other focus mode
                icon=""
                ;;
        esac
        
        # Highlight current mode
        if [ "$mode" = "$CURRENT_MODE" ]; then
            bgcolor="$POPUP_BACKGROUND_COLOR"
        else
            bgcolor="0x00000000"
        fi
        
        sketchybar --add item "focus_mode_$i" popup.focus_mode \
                   --set "focus_mode_$i" \
                       icon="$icon" \
                       icon.color="$color" \
                       label="$mode" \
                       label.color="$LABEL_COLOR" \
                       background.color="$bgcolor" \
                       click_script="$CONFIG_DIR/plugins/focus_mode_click.sh '$mode'"
    done
    
    # Toggle the popup
    sketchybar --set focus_mode popup.drawing=toggle

elif [ "$1" = "Off" ]; then
    # Turn off focus mode
    osascript -e '
    tell application "System Events"
        try
            # Use the Control Center keyboard shortcut to toggle DND off
            keystroke "d" using {control down, command down}
        on error
            # Alternative method
            key code 26 using {control down, option down}
        end try
    end tell' 2>/dev/null
    sketchybar --set focus_mode popup.drawing=off
    
elif [ ! -z "$1" ] && [ "$1" != "toggle" ]; then
    # For specific focus modes, open Control Center and let user select
    # This is the most reliable approach since automating specific focus mode selection
    # varies greatly depending on user's setup
    osascript -e '
    tell application "System Events"
        try
            keystroke "d" using {control down, command down}
        end try
    end tell' 2>/dev/null
    
    sketchybar --set focus_mode popup.drawing=off
fi
