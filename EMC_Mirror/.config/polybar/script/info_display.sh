#!/bin/bash

#notify-send "info_display.sh: script started"

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
DISPLAY_INFO=""
DISPLAY_ICON="󰍺"

readonly NOTIFY_ID_I=100

get_display_state() {
	# Use mapfile to read xrandr output into an array
	local lines connections max_name_len display_state="" pango=$1

	mapfile -t lines < <(xrandr)

    connections=()
    max_name_len=0

	local part_1 part_2 clean_line name
	
	for line in "${lines[@]}"; do
		# Screen header
		if [[ $line == Screen* ]]; then
			display_state+="$line"$'\n\n'

		# Resolution list
		elif [[ $line =~ ^[[:space:]]{3}[0-9] ]]; then
			if [[ "$line" == *"*"* ]]; then
				[ $pango -eq 1 ] && display_state+="<span foreground='#00FF00'>$line</span>"$'\n'
				[ $pango -ne 1 ] && display_state+="$line"$'\n'
			else
				display_state+="$line"$'\n'
			fi

		# Connection status lines
		elif [[ $line == *"connected"* ]]; then

			# Remove the long bracketed part (normal left...)
			part_1="${line%% (*}"
			part_2="${line##*)}"

			# Combine interface/status and physical size
			clean_line="${part_1}${part_2}"

			# Track longest name for alignment (e.g., VGA-1)
			name="${clean_line%% *}"
			(( ${#name} > max_name_len )) && max_name_len=${#name}

			connections+=("$clean_line")
		fi
	done

    display_state+=$'\n'

	local conn name rest aligned_line
	
	# Align and append connections to DISPLAY_INFO
	for conn in "${connections[@]}"; do
		name="${conn%% *}"
		rest="${conn#* }"

		if [[ "$rest" == *"dis"* ]]; then
			printf -v aligned_line "%-${max_name_len}s  %s" "$name" "$rest"
		else
			# Print with padding to keep columns aligned
			[ $pango -eq 1 ] && printf -v aligned_line "<span foreground='#00FF00'>%-${max_name_len}s  %s</span>" "$name" "$rest"
			[ $pango -ne 1 ] && printf -v aligned_line "%-${max_name_len}s  %s" "$name" "$rest"
		fi
		display_state+="$aligned_line"$'\n'
	done

	echo "$display_state"
}

get_display_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" display_icon="󰍺" header_display=""
	local colored_display_icon="<span foreground='$color_primary'>$display_icon</span>"

	[ $pango -eq 1 ] && header_display="<b>\
$colored_display_icon DISPLAY Info</b> (click right to close)

"
	DISPLAY_INFO="$header_display"
	DISPLAY_INFO+="$(get_display_state $pango)\n"
}

if [ "$BUTTON" = "left" ]; then
	get_display_info
	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$DISPLAY_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_display_info nopango
	DISPLAY_INFO=$(printf "\n%b" "$DISPLAY_INFO")
	info_box "$DISPLAY_ICON DISPLAY Info box" "$DISPLAY_INFO"
fi
