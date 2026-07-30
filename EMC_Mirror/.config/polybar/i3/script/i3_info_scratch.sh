#!/bin/bash

#notify-send "i3_info_scratch.sh: script started"

BUTTON="$1"

SCRATCH_INFO=""

readonly NOTIFY_ID_I=100

get_scratchpad_data() {
	# Count windows in scratchpad
	local count scratchpad_apps scratchpad_data=""

	count=$(i3-msg -t get_tree | jq -r '.. | select(.name? == "__i3_scratch") | .. | select(.window? != null) | .name' | wc -l)

	# List full window titles (including filenames/websites)
	# We use a newline (\n) for better readability in the notify-send box

	scratchpad_apps=$(i3-msg -t get_tree | jq -r '.. | select(.name? == "__i3_scratch") | .. | select(.window? != null) | "\(.name) [\(.window_properties.instance)]"' | sed 's/^/- /')

	[ -z "$scratchpad_apps" ] && scratchpad_data="no apps"
	[ $count -eq 1 ] && scratchpad_data="$count window:\n\n$scratchpad_apps"
	[ $count -ne 1 ] && scratchpad_data="$count windows:\n\n$scratchpad_apps"

	echo "$scratchpad_data"
}

get_scratchpad_info() {

	local scratchpad_data="$(get_scratchpad_data)"

	local color_secondary="#8ABEFF" color_bg="#282A2E" scratch_icon="󰮉"  header_scratchpad=""
	local colored_scratch_icon="<span background='$color_bg' foreground='$color_secondary'> $scratch_icon </span>"

	header_scratchpad="<b>\
$colored_scratch_icon SCRATCHPAD Info</b>

"
	SCRATCH_INFO="$header_scratchpad"
	SCRATCH_INFO+="$scratchpad_data"$'\n'
}

if [ "$BUTTON" = "left" ]; then
	get_scratchpad_info
	# Send to Dunst with monospace formatting.
	notify-send -h string:x-dunst-stack-tag:control_s -r $NOTIFY_ID_I "" "<tt>$SCRATCH_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
fi

