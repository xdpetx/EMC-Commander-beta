#!/bin/bash

# Script to show launchbar 

PIDFILE="/tmp/polybar_launchbar.pid"


readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=1500

location=$1

if [ ! -f "$PIDFILE" ]; then
	# Start in the background (&) and save the Process ID (PID)
	case $location in
		"l" | "left") polybar launchbar_left & ;;
		"r" | "right") polybar launchbar_right & ;;
		*) polybar launchbar_center &
	esac

	echo $! > "$PIDFILE"

else
	true
	#notify-send -r $NOTIFY_ID -t $NOTIFY_TIME  "Cannot open another launchbar. Close the current one first"
fi

