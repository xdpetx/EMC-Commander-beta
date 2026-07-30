#!/bin/bash

BUTTON="$1"
KBD_INFO=""

readonly NOTIFY_ID_I=100

get_layout() {

	local key layout

	# get layout
	while IFS=':' read -r key layout; do
		if [ "$key" = "layout" ]; then
			layout=${layout##* }
			break
		fi
	done <<< $(setxkbmap -query)

	echo "$layout"
}

get_active_layout() {

	local layout active_layout active_index

	layout=$(get_layout)

	# get active layout
	active_index=$($_BINARIES/emc_get_active_kbd_layout)
	((active_index ++))
	active_layout=$(echo "$layout" | cut -d"," -f$active_index)

	echo "$active_layout"
}

get_kbd_state() {

	local kbd_state=""
	local line words caps_lock num_lock

	#  Parse xset q output using internal bash arrays to avoid awk/grep
	while read -r line; do
		case "$line" in
			*"Caps Lock:"*)
				# Line looks like: "00: Caps Lock: off    01: Num Lock: off ..."
				read -a words <<< "$line"
				caps_lock="${words[3]}"
				num_lock="${words[7]}"
				[ "$num_lock" = "off" ] && kbd_state+="<span foreground='#AAAAAA'>Num         : OFF</span>\n"
				[ "$num_lock" = "on" ]  && kbd_state+="<span foreground='#FFFF00'>Num         : ON</span>\n"
				[ "$caps_lock" = "off" ] && kbd_state+="<span foreground='#AAAAAA'>Caps        : OFF</span>\n\n"
				[ "$caps_lock" = "on" ]  && kbd_state+="<span foreground='#FFFF00'>Caps        : ON</span>\n\n"
				;;
			*"auto repeat delay:"*)
				#  Line: "  auto repeat delay:  660    repeat rate:  25"
				read -a words <<< "$line"
				# words[0]=auto, [1]=repeat, [2]=delay:, [3]=660, [4]=repeat, [5]=rate:, [6]=25
				kbd_state+="Repeat      : Delay ${words[3]} / Rate ${words[6]}\n"
				;;
			*"acceleration:"*)
				#  Line: "  acceleration:  2/1    threshold:  4"
				read -a words <<< "$line"
				# words[1] = 2/1, words[3] = 4
				kbd_state+="mouse-speed : ${words[1]} (treshold: ${words[3]}px)\n"
				;;
		esac
	done <<< "$(xset q)"

	echo "$kbd_state"
}

get_kbd_info() {
	local color_primary="#F0C674" kbd_icon="󰧺" header_kbd
	local colored_kbd_icon="<span foreground='$color_primary'>$kbd_icon</span>"
	local layout=$(get_layout) active_layout=$(get_active_layout)

	header_kbd="<b>\
$colored_kbd_icon KEYBOARD Info</b>

"
	KBD_INFO="$header_kbd"
	KBD_INFO+="layout      : <span foreground='#FFFFFF'>$layout</span>\n"
	KBD_INFO+="active      : <span foreground='#00FF00'>$active_layout</span>\n\n"
	KBD_INFO+=$(get_kbd_state)

}

get_kbd_info

if [ "$BUTTON" = "left" ]; then
	notify-send -h string:x-dunst-stack-tag:module_s -r $NOTIFY_ID_I "" "<tt>$KBD_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
fi
