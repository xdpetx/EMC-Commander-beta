#!/bin/bash

# check procedures for EMC_standalone_app_installer:
#
#	check_desktop_env, check_os
#
# DEBIAN VERSION

# check desktop and build packages list
check_desktop_env() {
	local session i3_sessions=0 

	AVAILABLE_DESKTOP_SESSIONS=""
	for session in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
		if [ -e "$session" ]; then
			session="${session##*/}"
			AVAILABLE_DESKTOP_SESSIONS+="$session "
		fi
	done

	DESKTOP_ENV="${DESKTOP_SESSION:-UNKNOWN_DESKTOP}"
	DLG_APPS=()
	[ ! "$DESKTOP_ENV" = "i3_EMC" ] && return 1

	DLG_APPS=(
	"${EMC_BASE_APPS[@]}" \
	"${SEPARATOR_OFFICE[@]}" \
	"${EMC_OFFICE[@]}" \
	"${SEPARATOR_NET[@]}" \
	"${EMC_NET[@]}" \
	"${SEPARATOR_GRAPHICS[@]}" \
	"${EMC_GRAPHICS[@]}" \
	"${SEPARATOR_GUI_TOOLS[@]}" \
	"${GUI_TOOLS[@]}" \
	"${SEPARATOR_CLI_TOOLS[@]}" \
	"${CLI_TOOLS[@]}" \
	"${SEPARATOR_CONFIG[@]}" \
	"${EMC_CONFIG[@]}" 
	"${SEPARATOR_DEVEL[@]}" \
	"${EMC_DEVEL[@]}" 
	)
}

# check os for info
check_os() {

	if [ -f /etc/os-release ]; then
		# get OS-vars
		source /etc/os-release
		OS="$PRETTY_NAME"  #e.g. "ubuntu", "debian", "arch"
		OS_LIKE="$ID_LIKE"
		OS_FAMILY="$ID"
	else
		OS="unknown"
		echo "Error - Unknown OS. Cannot install EMC tools."
		exit 1 # cannot install dependencies script aborted
	fi
}

check_inet() {

	INET_CONNECTED="false"
	
	# ping one of the root name servers
	! ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1 && return
	# verify connectivity
	! getent hosts debian.org > /dev/null 2>&1 && return

	INET_CONNECTED="true"
}

check_download_speed() {

	local errcode
	local logfile=$(mktemp)
	local size=10000000
#	URL="https://speed.cloudflare.com/__down?bytes=$size"
	URL="http://cachefly.cachefly.net/10mb.test"
#	URL="http://speedtest.tele2.net/10MB.zip"

	LC_ALL=C wget -4 -c --show-progress --progress=bar:force -O /dev/null "$URL" -o "$logfile"  2>&1 | tee "$logfile"

	errcode=${PIPESTATUS[0]}
	[ $errcode -ne 0 ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "wget errcode = $errcode"

	#DOWNLOAD_SPEED=$(cat "$logfile" | tail -n 1)
	DOWNLOAD_SPEED=$(grep -oE '[0-9.]+[[:space:]]+[A-Z]B/s' "$logfile" | tail -n 1)

	rm -f "$logfile"
}

check_focus() {

	local is_focused
	#sleep 0.1
	# is app installer main window focused ?
	is_focused=$(i3-msg -t get_tree | jq -r '.. | select(type=="object" and .window_properties?.instance == "EMC_App_Installer") | .focused // false')
	if [ "$is_focused" = "false" ]; then
		# this is not a valid i3 msg !
		i3-msg "[instance="EMC_App_Installer"] urgent enable" > /dev/null 2>&1
	fi
}
