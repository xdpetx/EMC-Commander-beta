#!/bin/bash

# call with parameter up/down
BUTTON="$1"

scroll_window() {
    # Define the mapping locally to avoid side effects
    local -A scroll_map
    
    # Mapping for scroll directions
    scroll_map["vertical_up"]="up"
    scroll_map["horizontal_up"]="left"
    scroll_map["vertical_down"]="down"
    scroll_map["horizontal_down"]="right"
    scroll_map["none_up"]="left"     # Handle single window cases
    scroll_map["none_down"]="right"

    # Get the current container orientation
    local ORIENTATION
    ORIENTATION=$(i3-msg -t get_tree | jq -r '.. | objects | select(.nodes[]?.focused==true).orientation')

    # Construct the lookup key using the orientation and the button direction (up/down)
    local LOOKUP_KEY="${ORIENTATION}_${BUTTON}"

    # Get the target, default to 'left' if the key is not found
    local TARGET_DIRECTION="${scroll_map[$LOOKUP_KEY]:-left}"

    # English comment: Execute the focus change in i3
    i3-msg focus "$TARGET_DIRECTION" > /dev/null
}
scroll_window
