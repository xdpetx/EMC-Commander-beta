#!/bin/bash

setup_monitor() {
	# Define local variables for monitor detection and paths
	local monitor_con resolution is_supported SUPPORTED_RES USRDIR
	
	is_supported="false"
	SUPPORTED_RES=(2560x1440 1920x1080 1680x1050 1600x900 1440x900 1280x1024 1366x768 1280x720 1024x768)
	
	# Setting USRDIR as requested
	USRDIR="$HOME/.config/polybar/usr"
	
	# Detect connected monitor and resolution
	monitor_con=$(xrandr | grep " connected" | awk '{print $1}' | head -n1)
	#resolution=$(xrandr | grep " connected" | awk '{print $3}' | cut -d+ -f1 | head -n1)
	# Extract resolution by pattern numberxnum ber, ignoring extra labels like "primary"
	resolution=$(xrandr | grep " connected" | grep -oE '[0-9]+x[0-9]+' | head -n1)

	# Check if the resolution is supported
	for res in "${SUPPORTED_RES[@]}"; do
		if [ "$resolution" = "$res" ]; then
			is_supported="true"
			break
		fi
	done

	if [ "$is_supported" = "true" ]; then
		echo -e "Monitor connected on: $monitor_con | Resolution: $resolution"
		
		# Reference to the monitor subfolder within USRDIR
		local template="$USRDIR/monitor/monitor_$resolution.ini"
		local target="$USRDIR/monitor.ini"

		if [ -f "$template" ]; then
			echo -e "copy monitor_$resolution.ini to monitor.ini"
			cp "$template" "$target"
		else
			echo -e "  Error: Template $template not found!"
		fi
		
	else
		echo -e "Monitor connected on: $monitor_con | Resolution: $resolution is NOT supported"
		echo -e "Please edit $USRDIR/monitor.ini for your resolution manually"
	fi
}

setup_monitor
