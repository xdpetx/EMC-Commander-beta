#!/bin/bash

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"

# Default values
CLASS="N/A"
INSTANCE="N/A"
TITLE="N/A"
WIN_ID="N/A"
IS_STICKY="N/A"
IS_FLOATED="N/A"

WINDOW_INFO=""
WINDOW_ICON="󱂬"

readonly NOTIFY_ID_I=100

on_scroll() {
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

	# Execute the focus change in i3
	i3-msg focus "$TARGET_DIRECTION" > /dev/null
}

get_window_data() {
	# Fetch the entire tree and extract focused window properties in one go
    # This retrieves metadata and the sticky/floating states from the i3 IPC
	local tree focused_node sticky_raw floating_raw

	tree=$(i3-msg -t get_tree)

	# Use jq to isolate the focused node and its properties
	focused_node=$(echo "$tree" | jq -r '.. | select(.focused? == true)')

	if [[ -n "$focused_node" && "$focused_node" != "null" ]]; then
		# Parse standard properties
		CLASS=$(echo "$focused_node" | jq -r '.window_properties.class // "N/A"')
		INSTANCE=$(echo "$focused_node" | jq -r '.window_properties.instance // "N/A"')
		TITLE=$(echo "$focused_node" | jq -r '.window_properties.title // "N/A"')
		WIN_ID=$(echo "$focused_node" | jq -r '.window // "N/A"')

		# Parse states for sticky and floating
		# Convert boolean/string states to readable ON/OFF indicators
		sticky_raw=$(echo "$focused_node" | jq -r '.sticky')
		floating_raw=$(echo "$focused_node" | jq -r '.floating')

		[[ "$sticky_raw" == "true" ]] && IS_STICKY="ON 📌" || IS_STICKY="OFF"
		[[ "$floating_raw" == *"on"* ]] && IS_FLOATED="ON ☁️" || IS_FLOATED="OFF"
	fi
}

prepare_window_data() {
	# If CLASS is empty, do nothing
	[[ -z "$CLASS" || "$CLASS" == "N/A" ]] && return

	pango=$1

	[ $pango -eq 1 ] && [ ${#TITLE} -gt 50 ] && TITLE="${TITLE:0:50} ..."

	[ $pango -eq 1 ] && CLASS="<span foreground='#00FF00'>$CLASS</span>"
	[ $pango -eq 1 ] && TITLE="<span foreground='#00FF00'>$TITLE</span>"

	# We construct the message with true line breaks.
	# The spacing is chosen so that they are aligned vertically.
	# Important: Do NOT use `printf` here; instead, assign the text directly.
	local window_data="
Class    :  $CLASS
Instance :  $INSTANCE
Title    :  $TITLE
Window ID:  $WIN_ID
sticky   :  $IS_STICKY
floated  :  $IS_FLOATED
"
	echo "$window_data"
}

get_window_info() {
	local pango=0 window_data=""
	[ -z "$1" ] && pango=1

	get_window_data
	window_data="$(prepare_window_data $pango)"

	local color_secondary="#8ABEFF" color_bg="#282A2E" window_icon="󱂬" header_window=""
	local colored_window_icon="<span background='$color_bg' foreground='$color_secondary'> $window_icon </span>"

	[ $pango -eq 1 ] && header_window="<b>\
$colored_window_icon WINDOW Info</b> (click to close)
"
	WINDOW_INFO="$header_window"
	WINDOW_INFO+="$window_data"$'\n'
}

case "$BUTTON" in
	"up"|"down") 
		on_scroll
		exit 0 ;;
esac

if [ "$BUTTON" = "left" ]; then
	get_window_info
	# Send to Dunst with monospace formatting <tt>.
	notify-send -h string:x-dunst-stack-tag:control -r $NOTIFY_ID_I "" "<tt>$WINDOW_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_window_info nopango
	info_box "$WINDOW_ICON WINDOW Info box" "$WINDOW_INFO" 0 200
fi

