#!/bin/bash

# This is the event handler for [module/i3_workspaces]

#notify-send "i3_workspaces_event.sh started with parameter $1"

# Input arguments "left", "right",  "middle", "up", "down"
# Input arguments "dbl_left", "dbl_right",  "dbl_middle"
BUTTON=$1

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
	case $BUTTON in
		# edit this begin
		# toggle layout tabbed splith
		left	 ) i3-msg layout toggle tabbed splith;;
		# close workspace
		right	 ) i3-msg focus parent && i3-msg kill && i3-msg workspace prev;;
		# reset workspace to layout tabbed
		middle	 ) i3-msg "[workspace=__focused__ class=\".*\"] floating enable, [workspace=__focused__ class=\".*\"] floating disable, layout tabbed";;
		# toggle layout stacked splitv
		dbl_left ) i3-msg layout toggle stacking splitv;;
		#scroll workspaces
		up		 ) show_workspace_click_actions ;;
		down	 ) dunstctl close $NOTIFY_ID_H ;;
		# edit this end
	esac
}

show_workspace_click_actions() {

	local color_secondary="#8ABEFF" color_bg="#282A2E" color_fg="#C5C8C6"
	local click_action="" ws_icon="󰷔"
	local ws_icon_colored="<span background='$color_bg' foreground='$color_secondary'>$ws_icon</span>"
	local ws_output="<span background='$color_bg' foreground='$color_fg'> EMC </span>"
	local i_workspaces="<span background='$color_bg' foreground='$color_secondary'> 8 EMC   󰽯  󰋜  </span>"



	click_action+="\<b>$ws_icon_colored$ws_output Control WORKSPACE</b> Help <i>(scroll  to close)</i>

    click left   $ws_icon_colored: layout tabbed  / splith
dbl click left   $ws_icon_colored: layout stacked / splitv

    click right  $ws_icon_colored: close workspace
    click middle $ws_icon_colored: reset workspace layout tabbed

    click left/right on $ws_output show/hide Info
dbl click left       on $ws_output open Info box

click left $i_workspaces on launchbar to open a new workspace 
click right to open an alternate workspace

You can also use the i3 shortcuts for this.

scroll workspaces : scroll  on output
switch workspace  : click workspace icon on output or launchbar
"

	notify-send -h string:x-dunst-stack-tag:control_h -r $NOTIFY_ID_H -t 0 "" "<tt>$click_action</tt>"
}

# --- Main Execution ---
on_click

