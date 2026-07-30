#!/bin/bash

# This is the event handler for [module/i3_exit]

BUTTON=$1

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=2500

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
	case $BUTTON in
		# edit this begin
		left	) i3_exit ;;
		right	) i3_reload ;;
		middle	) i3_restart ;;
		up		) show_exit_click_actions ;;
		down	) dunstctl close $NOTIFY_ID_H ;;
		# edit this end
	esac
}


show_exit_dlg() {

	local EMC_EXIT_INSTANCE="EMC_Exit"
	local title=" exit EMC"

yad --name="$EMC_EXIT_INSTANCE" \
--title="$title" \
--window-icon="emc-application-exit" \
--center \
--button=" shut down!emc-shutdown:10" \
--button=" reboot!emc-reboot:20" \
--button=" exit EMC!emc-log-out:40" \
--button=" CANCEL!emc-gtk-cancel:1" \
--buttons-layout center

#--button=" log out!emc-log-out:30" \
}

run_exit_dlg() {

	local yad_exitcode=$1

	case $yad_exitcode in
		1|252)	exit 0;;
	esac

	# Cleanup System

	# reset all general i3 Flags (including specific protected flags below)
	rm -f /tmp/i3_*

	# load user specific cleanup
	source "$HOME/.config/polybar/usr/user_cleanup"

	sync
	sleep 1

	case $yad_exitcode in
		10) /usr/sbin/poweroff;;
		20) /usr/sbin/reboot;;
	#	30) i3-msg exit && loginctl terminate-user "$USER" ;;
		40) i3-msg exit;;
	esac
}

i3_reload() {

	i3-msg reload

	notify-send  -r $NOTIFY_ID -t $NOTIFY_TIME "EMC reload done"
}

i3_restart() {

i3-msg restart

notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "EMC restart done"
}

i3_exit() {

	local yad_exitcode lockfile="/tmp/polybar_i3exit.lock"

	[ -f "$lockfile" ] && exit
	touch "$lockfile"

	# first close all Info and Help notifies
	dunstctl close-all

	show_exit_dlg
	yad_exitcode=$?
	rm -f  "$lockfile"
	run_exit_dlg $yad_exitcode
}

show_exit_click_actions() {

	local click_action="" color_secondary=#8ABEFF color_alert="#A54242" color_fg="#C5C8C6"
	local i_exit="<span background='$color_secondary'>󰩈</span>"
	local exit_icon="<span background='$color_alert' foreground='$color_fg'> EXIT </span>"

	click_action+="\<b>$i_exit Control EXIT</b> Help

  click left   $exit_icon : exit    EMC  
  click right  $exit_icon : reload  EMC  
  click middle $exit_icon : restart EMC  
"
	notify-send -h string:x-dunst-stack-tag:control_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

# Main Execution 
on_click
