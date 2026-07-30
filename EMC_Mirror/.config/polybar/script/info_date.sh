#!/bin/bash

BUTTON="$1"
DATE_INFO=""

readonly NOTIFY_ID_I=100

get_date_info() {
	local color_primary="#F0C674" date_icon="" header_date
	local colored_date_icon="<span foreground='$color_primary'>$date_icon</span>"

	header_date="<b>\
$colored_date_icon DATE Info</b>

"
	DATE_INFO="$header_date"
	DATE_INFO+="Date: <span foreground='#00FF00'>$(date "+%a %d %B %Y")</span>\n"
	DATE_INFO+="Week: $(date "+%V / %Y")\n"
	DATE_INFO+="Time: $(date "+%X %Z")\n"
}

get_date_info

if [ "$BUTTON" = "left" ]; then
	notify-send -h string:x-dunst-stack-tag:module_s -r $NOTIFY_ID_I "" "<tt>$DATE_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
fi
