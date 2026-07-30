#!/bin/bash

readonly INFOBOX_INSTANCE="EMC_Info_Box"
readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=1500

info_box() {
	local lockfile="/tmp/polybar_infobox.lock"

	if [ -f "$lockfile" ]; then
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "Cannot open another info box. Close the current one first"
		return
	fi

	touch "$lockfile"

	local title="$1" msg="$2" width=${3:-800} height=${4:-600}
	local res screen_width screen_height yad_exitcode  IFS='x' 

	res=$(LC_ALL=C xrandr --query | grep "*" | xargs)
	res=${res%% *}

	read -r screen_width screen_height <<< "$res"

	screen_width=$(( screen_width * 95 / 100))
	screen_height=$(( screen_height * 85 / 100))

	[ $width -eq 0 ] && width=800
	[ $width -gt $screen_width ] && width=$screen_width
	[ $height -gt $screen_height ] && height=$screen_height

printf "%s" "$msg" | yad --name="$INFOBOX_INSTANCE" \
--text-info \
--title="$title" \
--width="$width" --height="$height" \
--window-icon="" \
--fontname="Monospace 12" \
--button="OK!gtk-ok:0" \
--button="copy to clipboard!emc-document-save:10" \
--buttons-layout=center \
--center

	yad_exitcode=$?

	rm -f  "$lockfile" 

	[ $yad_exitcode -ne 10 ] && return
	printf "%s" "$msg" | xsel --clipboard --input
	notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "Content copied to clipboard"
}
