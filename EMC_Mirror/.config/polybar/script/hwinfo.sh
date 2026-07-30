#!/bin/bash

HWINFO_HTML="/tmp/EMC_hw.html"

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=1500

# first close all Info and Help notifies
dunstctl close-all

if [ ! -f "$HWINFO_HTML" ]; then
	pkexec lshw -html > "$HWINFO_HTML"
	exitcode=$?

	if [ ! -s "$HWINFO_HTML" ]; then
		rm -f "$HWINFO_HTML"
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ HWINFO warning" "\nempty HWINFO file - exitcode = $exitcode"
		exit
	fi
fi

[ -f "$HWINFO_HTML" ] && xdg-open "$HWINFO_HTML"
