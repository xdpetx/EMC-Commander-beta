#!/bin/bash

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
MEMORY_INFO=""
MEMORY_ICON="󰘚"

readonly NOTIFY_ID_I=100

# Efficiently parse meminfo and format output without external processes
get_memory_state() {
	local key val val_kb val_mb val_gb memory_state=""
	local fmt="%-15s %10s kB / %8s MB / %5s GB\n"

	while IFS=':' read -r key val; do
		# Remove spaces from key
		key="${key// /}"
		
		# Extract pure numeric value for kB
		val_kb="${val//kB/}"
		val_kb="${val_kb// /}"

		case "$key" in
			MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree|"Active(file)"|"Inactive(file)")
				val_mb=$(echo "scale=2; $val_kb / 1024" | bc)
				val_gb=$(echo "scale=2; $val_kb / 1048576" | bc)
				# Format and append to MEMORY_INFO using printf -v (no subshell)
				printf -v line "$fmt" "$key:" "$val_kb" "$val_mb" "$val_gb"
				memory_state+="$line"
				
				# Add empty lines after specific blocks
				if [[ "$key" =~ (MemAvailable|Inactive\(file\)|SwapFree) ]]; then
					MEMORY_INFO+="\n"
				fi
				;;
			Dirty)
				# Dirty usually stays in kB
				printf -v line "%-15s %10s kB\n" "$key:" "$val_kb"
				memory_state+="$line"
				break
				;;
		esac
	done < /proc/meminfo

	echo "$memory_state"
}

get_memory_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" memory_icon="󰘚" header_memory=""
	local colored_memory_icon="<span foreground='$color_primary'>$memory_icon</span>"

	[ $pango -eq 1 ] && header_memory="<b>\
$colored_memory_icon MEMORY Info</b> (click right to close)

"
	MEMORY_INFO="$header_memory"
	MEMORY_INFO+="$(get_memory_state)\n"
}

if [ "$BUTTON" = "left" ]; then
	get_memory_info

	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$MEMORY_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_memory_info nopango

	MEMORY_INFO=$(printf "\n%b" "$MEMORY_INFO")
	info_box "$MEMORY_ICON MEMORY Info" "$MEMORY_INFO" 600 300
fi

