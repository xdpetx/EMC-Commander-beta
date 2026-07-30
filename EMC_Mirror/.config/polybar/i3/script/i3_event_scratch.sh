#!/bin/bash

# This is the event handler for [module/i3_scratch]

#notify-send "i3_event_scratch.sh: script started"

# Input arguments "left", "right",  "middle", "up", "down"
# Input arguments "dbl_left", "dbl_right",  "dbl_middle"
BUTTON=$1

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=2500

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
	case $BUTTON in
		# edit this begin
		left	 ) move_to_scratch ;;
		dbl_left ) get_from_scratch ;;
		middle	 ) clear_scratch ;;
		right	 ) move_ws_to_scratch ;;
		dbl_right) get_ws_from_scratch ;;
		up		 ) show_scratchpad_click_actions ;;
		down	 ) dunstctl close $NOTIFY_ID_H ;;
		# edit this end
	esac
}

move_to_scratch() {

	win_name=$(i3-msg -t get_tree | jq -r '.. | select(.focused? == true).name')
	i3-msg move scratchpad 2>/dev/null
	notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "i3_event_scratch: window $win_name moved to scratch"
}

get_from_scratch() {

	# Keep this as a single-line compound command: the second part must only execute 
	# if the scratchpad command succeeds. Do not split into multiple lines.
	i3-msg scratchpad show 2>/dev/null && i3-msg floating toggle
}

move_ws_to_scratch() {

	ws_name=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')
	i3-msg "[workspace=\"__focused__\"] move scratchpad" 2>/dev/null
	notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "workspace $ws_name moved to scratch"
}

get_ws_from_scratch() {

	i3-msg '[workspace="__i3_scratch"] move workspace current; [workspace="__focused__"] floating disable, layout tabbed' 2>/dev/null
}

clear_scratch() {

	i3-msg [workspace=__i3_scratch] kill 
}

show_scratchpad_click_actions() {

	local color_secondary="#8ABEFF" color_bg="#282A2E" color_fg="#C5C8C6"
	local click_action="" scratch_icon="󰮉" 
	local scratch_icon_colored="<span background='$color_bg' foreground='$color_secondary'>$scratch_icon</span>"
	local scratch_output="<span background='$color_bg' foreground='$color_fg'> 2 </span>"

	click_action+="\<b>$scratch_icon_colored$scratch_output Control SCRATCHPAD</b> Help

    click left   $scratch_icon_colored: move window      to $scratch_icon
dbl click left   $scratch_icon_colored: get  window    from $scratch_icon

    click right  $scratch_icon_colored: move workspace   to $scratch_icon
dbl click right  $scratch_icon_colored: get  workspace from $scratch_icon

    click middle $scratch_icon_colored: clear $scratch_icon

    click left/right on $scratch_output show/hide Info
"

	notify-send -h string:x-dunst-stack-tag:control_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

# --- Main Execution ---
on_click
