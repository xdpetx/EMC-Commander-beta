#!/bin/bash

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

dlg_kbd_test() {

	local kbd_icon="󰧺" active_layout=$(get_active_layout)

yad --entry --width=500 \
--title="Module KEYBOARD active layout: $active_layout" \
--window-icon="" \
--text="Test keyboard layout" \
--button="OK!gtk-ok:0" \
--buttons-layout=center \
--center

	echo "$pkg"
}

dlg_kbd_test
