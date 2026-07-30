#!/bin/bash

# This is the event handler for [module/i3_windows]

#notify-send "i3_windows_event.sh started with parameter $1"

# Input arguments "left", "right",  "middle", "up", "down"
# Input arguments "dbl_left", "dbl_right",  "dbl_middle"
BUTTON=$1

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
	case $BUTTON in

		# edit this begin
		# close window
		right	 ) i3-msg kill;;
		# toggle float
		middle	 ) i3-msg floating toggle;;
		# toggle sticky
		# Note: Window must be in floating mode for this to have a visual effect.
		dbl_right)  i3-msg sticky toggle ;;
		up		 ) show_window_click_actions ;;
		down	 ) dunstctl close $NOTIFY_ID_H ;;
		# edit this end
	esac
}

show_window_click_actions() {

	local color_secondary="#8ABEFF" color_bg="#282A2E" color_fg="#C5C8C6"
	local click_action="" window_icon=""
	local window_icon_colored="<span background='$color_bg' foreground='$color_secondary'>$window_icon</span>"
	local window_output="<span background='$color_bg' foreground='$color_fg'> Des </span>"

	click_action+="\<b>$window_icon_colored$window_output Control WINDOW</b> Help

    click-right  $window_icon_colored : close 
dbl click-right  $window_icon_colored : toggle sticky
    click-middle $window_icon_colored : toggle float

scroll up/down on output behind $window_icon_colored : next/prev window

    click left/right on $window_output show/hide Info
dbl click left       on $window_output open Info box

To focus a window click left the title bar or scroll 
To close a window you can click right the title bar too
"

	notify-send -h string:x-dunst-stack-tag:control_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

# --- Main Execution ---
on_click
