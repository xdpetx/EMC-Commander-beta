#!/bin/bash

# Function to count current scratchpad windows
count_scratch() {
	i3-msg -t get_tree | jq '.. | select(.name? == "__i3_scratch") | .floating_nodes | length' 2>/dev/null
}

# Initial count when starting
count_scratch

# Use i3's IPC to wait for window events. 
# This line makes the script "sleep" until i3 sends a notification.
i3-msg -t subscribe -m '[ "window" ]' | while read -r event; do
	count_scratch
done
