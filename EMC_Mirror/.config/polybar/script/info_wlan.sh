#!/bin/bash

#notify-send "info_wlan.sh: script started"

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
WLAN_INFO=""
WLAN_ICON="󰖩"

readonly NOTIFY_ID_I=100

# Functionality not tested, no Wi-Fi available
get_wlan_state() {
 
	#  Iterate over nmcli output and filter for the active connection using Bash
	local line found temp interface ssid signal bars ip_info ip wlan_state=""

	found=false

	#  Process each line of nmcli directly in Bash
	while IFS= read -r line; do
		if [[ "$line" == "yes:"* ]]; then
			#  Use the same parameter expansion logic as in get_key
			temp="${line#yes:}"
			interface="${temp%%:*}"

			temp="${temp#*:}"
			ssid="${temp%%:*}"

			temp="${temp#*:}"
			signal="${temp%%:*}"
			bars="${temp#*:}"
			
			#  Get IP and strip CIDR using pure Bash
			ip_info=$(ip -4 addr show "$interface")
			ip ip="${ip_info#*inet }"
			ip="${ip%%/*}"

			wlan_state=$(printf "Interface : %s\nSSID      : %s\nSignal    : %s%% (%s)\nIP        : %s\n" \
				"$interface" "${ssid:-N/A}" "$signal" "$bars" "${ip:-disconnected}")
			found=true
			break
		fi
	done < <(nmcli -t -f active,device,ssid,signal,bars dev wifi)

	if [ "$found" = false ]; then
		wlan_state="Status    : No active WiFi connection\n"
	fi

	echo "$wlan_state"
}

get_wlan_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" wlan_icon="󰖩" header_wlan=""
	local colored_wlan_icon="<span foreground='$color_primary'>$wlan_icon</span>"

	[ $pango -eq 1 ] && header_wlan="<b>\
$colored_wlan_icon WLAN Info</b> (click right to close)

"
	WLAN_INFO="$header_wlan"
	WLAN_INFO+=$(get_wlan_state)
}

if [ "$BUTTON" = "left" ]; then
	get_wlan_info
	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$WLAN_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_wlan_info nopango
	WLAN_INFO=$(printf "\n%b" "$WLAN_INFO")
	info_box "$WLAN_ICON WLAN Info" "$WLAN_INFO"
fi

