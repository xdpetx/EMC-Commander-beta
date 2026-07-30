#!/bin/bash

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
PULSEAUDIO_INFO=""
PULSEAUDIO_ICON=""
BLUETOOTH_INFO=""
BLUETOOTH_ICON=""

readonly NOTIFY_ID_S=100
readonly NOTIFY_ID_L=101
readonly NOTIFY_ID_R=102

readonly NOTIFY_ID_I=100

# Function to gather detailed audio information
get_pulseaudio_state() {

	local pango=$1 pulseaudio_state=""

	# 1. Get the active output device (Sink)
	local device="$(LC_ALL=C pactl get-default-sink)\n"
	local device_found="$device"

	[ -z "$device" ] && device="no audio device detected"

	# 2. Get current volume and mute status
	local vol=$(LC_ALL=C pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -n 1)
	local mute=$(LC_ALL=C pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

	# 3. Get microphone status (Source)
	local mic_mute=$(LC_ALL=C pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')

	# 4. List apps currently using audio
	local apps=$(LC_ALL=C pactl list sink-inputs | grep "application.name =" | cut -d'"' -f2 | sort -u | paste -sd ", ")
	[ -z "$apps" ] && apps="none"

	# Formatting the output for notify-send
	pulseaudio_state+="Device: $device\n"

	[ $pango -eq 1 ] && mute=$([ "$mute" = "no" ] && echo "<span foreground='#FFFF00'>Audio : ON</span> $vol%" || echo "<span foreground='#AAAAAA'>Audio : OFF</span>")
	[ $pango -ne 1 ] && mute=$([ "$mute" = "no" ] && echo "Audio : ON $vol%" || echo "Audio : OFF")
	[ ! -z "$device_found" ] && pulseaudio_state+="$mute\n"
	# micro
	[ $pango -eq 1 ] && mic_mute=$([ "$mic_mute" = "no" ] && echo "<span foreground='#FFFF00'>Micro : ON</span>" || echo "<span foreground='#AAAAAA'>Micro : OFF</span>")
	[ $pango -ne 1 ] && mic_mute=$([ "$mic_mute" = "no" ] && echo "Micro : ON" || echo "Micro : OFF")
	[ ! -z "$device_found" ] && pulseaudio_state+="$mic_mute\n\n"

	pulseaudio_state+="Apps  : $apps\n"

	echo "$pulseaudio_state"
}

# not ready - output!
get_bluetooth_state() {

	local pango=$1 bluetooth_state=""

	# LC_ALL=C for consistent English language output!
	local controller=$(LC_ALL=C bluetoothctl show | sed '/Pairable:/q')
	local devices=$(LC_ALL=C bluetoothctl devices)

	[ -z "$controller" ] && controller="Bluetooth adapter not found"
	[ -z "$devices" ] && devices="no devices paired"

	bluetooth_state+="$controller\n\n"
	bluetooth_state+="$devices\n"

	echo "$bluetooth_state"
}

get_pulseaudio_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" pulseaudio_icon="" bluetooth_icon=""
	local colored_pulseaudio_icon="<span foreground='$color_primary'>$pulseaudio_icon</span>"
	local colored_bluetooth_icon="<span foreground='$color_primary'>$bluetooth_icon</span>"

	local header_pulseaudio="\
PULSEAUDIO Info

"

	local header_bluetooth="\
BLUETOOTH Info

"

	[ $pango -eq 1 ] && header_pulseaudio="<b>\
$colored_pulseaudio_icon PULSEAUDIO Info</b> (click to close)

"
	[ $pango -eq 1 ] && header_bluetooth="<b>\
$colored_bluetooth_icon BLUETOOTH Info</b>

"
	PULSEAUDIO_INFO+="$header_pulseaudio"
	PULSEAUDIO_INFO+="$(get_pulseaudio_state $pango)\n"
	PULSEAUDIO_INFO+="$header_bluetooth"
	PULSEAUDIO_INFO+="$(get_bluetooth_state $pango)\n"
}

if [ "$BUTTON" = "left" ]; then

	get_pulseaudio_info
	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$PULSEAUDIO_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_pulseaudio_info nopango
	PULSEAUDIO_INFO=$(printf "\n%b" "$PULSEAUDIO_INFO")
	info_box "$PULSEAUDIO_ICON PULSEAUDIO Info box" "$PULSEAUDIO_INFO" 600
fi
