#!/bin/bash

#notify-send "info_eth.sh: script started"

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
ETH_INFO=""
ETH_ICON="󰈀"

readonly NOTIFY_ID_I=100

get_eth_state() {

	local eth_state=$(LC_ALL=C nmcli | sed '/Use "nmcli/,$d' | sed 's/^        //')

	echo "$eth_state"
}

get_eth_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" eth_icon="󰧺" header_eth=""
	local colored_eth_icon="<span foreground='$color_primary'>$eth_icon</span>"

	[ $pango -eq 1 ] && header_eth="<b>\
$colored_eth_icon ETHERNET Info</b> (click to close)

"
	ETH_INFO="$header_eth"
	ETH_INFO+="$(get_eth_state)\n"
}

if [ "$BUTTON" = "left" ]; then
	get_eth_info
	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$ETH_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_eth_info nopango
	ETH_INFO=$(printf "\n%b" "$ETH_INFO")
	info_box "$ETH_ICON Ethernet Info" "$ETH_INFO"
fi
