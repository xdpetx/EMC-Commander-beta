#!/bin/bash

#notify-send "info_filesys.sh: script started"

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
FILESYS_INFO=""
FILESYS_ICON="󰋊"

readonly NOTIFY_ID_I=100

get_filesys_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" filesys_icon="󰋊"
	local colored_filesys_icon="<span foreground='$color_primary'>$filesys_icon</span>"

	local disk_usage=$(printf "%-8s %-8s %7s %5s %-20s %-11s %-11s %s" "NAME" "FSTYPE" "SIZE" "FSUSE" "MOUNTPOINT" "UUID" "MODE" "LABEL")$'\n'
	local inodes=$(LC_ALL=C df -h -i -x tmpfs -x efivarfs)
	local header_disk_usage="" header_inodes=""

	[ $pango -ne 1 ] && disk_usage=$(printf "%-7s %-8s %7s %5s %-35s %-36s %-10s %s" "NAME" "FSTYPE" "SIZE" "FSUSE" "MOUNTPOINT" "UUID" "MODE" "LABEL")$'\n'
while IFS= read -r line; do

	NAME=""; FSTYPE=""; SIZE=""; FSUSE_PCT=""; MOUNTPOINT=""; UUID=""; MODE=""; LABEL=""
	eval "$line"
	[ ${#NAME} -gt 3 ] && NAME="  $NAME"
	[ ${#MOUNTPOINT} -gt 35 ] && MOUNTPOINT="${MOUNTPOINT:0:32}..."
	[ $pango -eq 1 ] && [ ${#MOUNTPOINT} -gt 20 ] && MOUNTPOINT="${MOUNTPOINT:0:17}..."
	[ $pango -eq 1 ] && [ ${#UUID} -gt 10 ] && UUID="${UUID:0:7}..."
	[ $pango -eq 1 ] && [ ${#LABEL} -gt 15 ] && LABEL="${LABEL:0:12}..."

	[ $pango -eq 1 ] && disk_usage+=$(printf "%-8s %-8s %7s %5s %-20s %-11s %-11s %s" "$NAME" "$FSTYPE" "$SIZE" "$FSUSE_PCT" "$MOUNTPOINT" "$UUID" "$MODE" "$LABEL")$'\n'
	[ $pango -ne 1 ] && disk_usage+=$(printf "%-7s %-8s %7s %5s %-35s %-36s %-10s %s" "$NAME" "$FSTYPE" "$SIZE" "$FSUSE_PCT" "$MOUNTPOINT" "$UUID" "$MODE" "$LABEL")$'\n'
done < <(LC_ALL=C lsblk -e 7 -o NAME,FSTYPE,SIZE,FSUSE%,MOUNTPOINT,UUID,MODE,LABEL -yP)

	header_disk_usage="<b>\
$colored_filesys_icon FILESYS Info - Disk Usage</b> (click to close)

"

	[ $pango -ne 1 ] && header_disk_usage="
FILESYS Info - Disk Usage

"

	header_inodes="<b>
$colored_filesys_icon FILESYS Info - Inodes</b>

"

	[ $pango -ne 1 ] && header_inodes="

FILESYS Info -Inodes

"

	FILESYS_INFO+="$header_disk_usage"
	FILESYS_INFO+="$disk_usage"
	FILESYS_INFO+="$header_inodes"
	FILESYS_INFO+="$inodes"$'\n'
}

if [ "$BUTTON" = "left" ]; then
	get_filesys_info
	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$FILESYS_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_filesys_info nopango
	info_box "$FILESYS_ICON FILESYS Info box" "$FILESYS_INFO" 1100
fi

