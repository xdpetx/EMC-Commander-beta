#!/bin/bash

#notify-send "i3_info_move.sh: script started"
CONTROL=$1
BUTTON=$2
MOVE_ICON="󰆾"

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
	case $BUTTON in
		up		 ) show_move_click_actions ;;
		down	 ) dunstctl close $NOTIFY_ID_H ;;
	esac
}

get_move_info() {

	local color_secondary="#8ABEFF" color_bg="#282A2E"
	local icons_horizontal="<span background='$color_bg' foreground='$color_secondary'>   </span>"
	local icons_vertical="<span background='$color_bg' foreground='$color_secondary'>   </span>"
	local icon_move_to="<span background='$color_bg' foreground='$color_secondary'>󰆾</span>"

case "$CONTROL" in

	move_left | move_right)
	connected_monitors=$(xrandr --query | grep -w "connected" | wc -l)

MOVE_INFO="\
    click left  $icons_horizontal : moves window left or right
dbl click left  $icons_horizontal : moves window to workspace prev or next
"

[ $connected_monitors -gt 1 ] && MOVE_INFO+="
    click right $icons_horizontal: moves window    to output prev or next
dbl click right $icons_horizontal: moves workspace to output prev or next
"

MOVE_INFO+="
use [win] and scroll on titlebar to move selected window left or right

💡 NOTE: the layout may change click middle on workspace icon to reset to tabbed
"
;;
	move_up | move_down)
MOVE_INFO="\
    click left $icons_vertical: moves window up or down
dbl click left $icons_vertical: moves window to workspace prev or next

use [shift] + [win] and scroll on titlebar to move selected window up   or down

💡 NOTE: the layout may change click middle on workspace icon to reset to tabbed
"
;;
	move_to)
MOVE_INFO="\
    click left $icon_move_to: moves single window   to another workspace
dbl-click left $icon_move_to: moves whole workspace to another workspace
"
;;

esac
}

show_move_click_actions() {

	get_move_info

	local color_secondary="#8ABEFF" color_bg="#282A2E"
	local click_action="" move_icon="󰆾"
#	local move_icon_colored="<span foreground='$color_secondary'>$move_icon</span>"
	local move_icon_colored="<span background='$color_bg' foreground='$color_secondary'>$move_icon</span>"

	click_action+="\<b>$move_icon_colored Control MOVE</b> Help

$MOVE_INFO"

	notify-send -h string:x-dunst-stack-tag:control_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

on_click
# Send to Dunst with monospace formatting.
# notify-send -h string:x-dunst-stack-tag:control_h -r $NOTIFY_ID_H "$MOVE_ICON Control MOVE" "\n<tt>$MOVE_INFO</tt>"
