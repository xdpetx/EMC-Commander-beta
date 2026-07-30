#!/bin/bash

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"

# Global variable for workspace and polybar data
WS_DATA=""
WS_INFO=""
WS_ICON="󰷔"

readonly NOTIFY_ID_I=100

# --- Data Provider Procedure ---
get_workspace_data() {
	# Order: focused, layout, output, num, name.
	WS_DATA=$(i3-msg -t get_tree | jq -r '
		.. 
		| select(.type? == "workspace" or .window_properties?.class == "Polybar") 
		| if .type == "workspace" 
		then "WS|\(any(..; .focused? == true))|\(.nodes[0].layout)|\(.output)|\(.num)|\(.name)"
		else "PB|\(.sticky)|sticky|\(.output)|PB|\(.name)"
		end')
}

# --- Output Procedure ---
prepare_workspace_data() {

	local workspace_data=""

	while IFS='|' read -r type focused layout output num name; do
		[[ -z "$type" ]] && continue

		if [[ "$type" == "WS" ]]; then
			local f_mark="no"
			local line_content=""

			# If focused is YES, wrap the entire line in a color tag.
			if [[ "$focused" == "true" ]]; then
				f_mark="YES"
				line_content=$(printf "FOCUSED: %-3s  LAYOUT: %-10.10s  OUTPUT: %-8.8s  NUM: %2s  NAME: %s" \
					"$f_mark" "$layout" "$output" "$num" "$name")
				if [ "$BUTTON" = "dbl_left" ]; then
					workspace_data+="$line_content\n"
				elif [ "$BUTTON" = "left" ]; then
					# Green color for the focused workspace.
					workspace_data+="<span foreground='#00FF00'>$line_content</span>\n"
				fi
			else
				workspace_data+=$(printf "FOCUSED: %-3s  LAYOUT: %-10.10s  OUTPUT: %-8.8s  NUM: %2s  NAME: %s" \
					"$f_mark" "$layout" "$output" "$num" "$name")"\n"
			fi
		else
			# Polybar line (unchanged)
			workspace_data+=$(printf "FOCUSED: %-3s  STICKY: %-10.10s  OUTPUT: %-8.8s  NUM: %2s  NAME: %s" \
				"-" "$focused" "$output" "PB" "$name")"\n"
		fi
	done <<< "$WS_DATA"

	echo "$workspace_data"
}

get_workspace_info() {
	local pango=0 workspace_data=""
	[ -z "$1" ] && pango=1

	get_workspace_data
	workspace_data="$(prepare_workspace_data $pango)"

	local color_secondary="#8ABEFF" color_bg="#282A2E" ws_icon="󰷔" header_ws=""
	local colored_ws_icon="<span background='$color_bg' foreground='$color_secondary'> $ws_icon </span>"

	[ $pango -eq 1 ] && header_ws="<b>\
$colored_ws_icon WORKSPACE Info</b> (click to close)

"
	WS_INFO="$header_ws"
	WS_INFO+="$workspace_data"
}

is_urgent() {
	local ws_urgent=$(i3-msg -t get_tree | jq -r 'recurse(.nodes[], .floating_nodes[]) | select(.urgent == true) | .name' | head -n 1)

	if [ -n "$ws_urgent" ] && [ "$ws_urgent" != "null" ]; then
		local current_ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')

		if [ ! "$ws_urgent" =  "$current_ws" ]; then
			i3-msg workspace "$ws_urgent"
		else
			local NOTIFY_ID=1003
			local NOTIFY_TIME=2500

			notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ focus urgent window first!"
		fi
		return 0
	fi
	return 1
}

# --- Main ---

if [ "$BUTTON" = "left" ]; then
	is_urgent && exit
	get_workspace_info
	# Send to Dunst with monospace formatting <tt>.
	notify-send -h string:x-dunst-stack-tag:control -r $NOTIFY_ID_I "" "<tt>$WS_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_workspace_info nopango
	WS_INFO=$(printf "\n%b" "$WS_INFO")
	info_box "$WS_ICON Workspace Info" "$WS_INFO" 900 300
fi

