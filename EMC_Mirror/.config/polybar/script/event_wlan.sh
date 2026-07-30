#!/bin/bash

# This is the event handler for [module/wlan]

#notify-send "wlan_event_handler:script started"

# Input arguments
BUTTON=$1     # "left", "right"
WS_NAME=$2    # Optional context (workspace name)

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=2500

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
case $BUTTON in
	# edit this begin
	"left") connect ;;
	"dbl_left") eval $(exec_key wlan_dbl_left) & ;;
	"right") eval $(exec_key wlan_right) & ;;
	"dbl_right") eval $(exec_key wlan_dbl_right) & ;;
	"up") show_wlan_click_actions ;;
	# edit this end
esac
}

# Procedure: connect
connect() {

	if [ $(nmcli networking) = "enabled" ]; then
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME  "Network Manager" "\ndisconnecting eth ..."
		nmcli networking off
	else
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME  "Network Manager" "\nconnecting eth ..."
		nmcli networking on
	fi

}

# Function: exec_key
# Load users app from applications.ini
function exec_key() {
	local APP_INI APP_CONTENT key appkey app cmd cmd_script

	APP_INI="$_USERDIR/applications.ini"
	APP_CONTENT=$(cat "$APP_INI")
	key="$1"

	# Parse applications.ini using pure bash parameter expansion for performance
	while IFS='=' read -r appkey app; do
		appkey=${appkey%% *}
		if [ "$appkey" = "[app-launch]" ]; then break; fi
		if [ "$appkey" = "$key" ]; then 
			# Remove leading whitespace (nested parameter expansion)
			app="${app#${app%%[![:space:]]*}}"
			# Remove trailing whitespace (nested parameter expansion)
			app="${app%${app##*[![:space:]]}}"
			if [ -z "$app" ]; then
				app="notify-send -r $NOTIFY_ID -t $NOTIFY_TIME '⚠️ EMC Warning' '\non-click $key: No command defined in applications.ini'"
				echo "$app"
				break
			else
				# Remove quotes ONLY if they enclose the ENTIRE string
				if [[ "$app" == \"*\" ]]; then
					app="${app#\"}"
					app="${app%\"}"
				elif [[ "$app" == \'*\' ]]; then
					app="${app#\'}"
					app="${app%\'}"
				fi
			fi
			app="${app%&}"
			cmd=${app%% *}
			cmd_script=$(eval echo "$app")
			# STEP 1: Check only the binary ($cmd). Quotes ("$cmd") prevent issues with spaces in paths and treat the binary as one single file.
			if ! command -v "$cmd" >/dev/null 2>&1; then
				# is $app a script?
				if [ -x "$cmd_script" ]; then
					eval "$app" &
					return
				fi
				notify-send -r $NOTIFY_ID -t $NOTIFY_TIME  "⚠️ EMC Warning" "\n$key = $app: application is not installed"
				return
			# STEP 2: Check the full command string ($app) WITHOUT quotes. No quotes allow 'word splitting', so 'command -v' can separate 
			# the binary from its arguments (e.g., -r). Using quotes here would incorrectly search for a filename containing spaces/args.
			elif ! bash -n <<< "$app" >/dev/null 2>&1; then 
				notify-send -r $NOTIFY_ID -t $NOTIFY_TIME  "⚠️ EMC Warning" "\n$key = $app: invalid command in applications.ini"
			fi

			echo "$app"
			break
		fi
	done <<< "$APP_CONTENT"
}

source "$_SCRIPTDIR/get_module_clicks.sh"

show_wlan_click_actions() {
	local wlan_iface=$(ls /sys/class/net/ | grep -E 'wlan|wlp|wlx' | head -n1)
	local connected="OFF"

	if [ -n "$wlan_iface" ]; then
		iwgetid -r "$wlan_iface" > /dev/null 2>&1
		[ $? -eq 0 ] && connected="ON"
	fi

	local color_primary="#F0C674" color_bg="#282A2E" color_fg="#C5C8C6"
	local click_action="" wlan_icon="󰖩"
	local wlan_icon_colored="<span foreground='$color_primary'>$wlan_icon</span>"
	local wlan_output="<span background='$color_bg' foreground='$color_fg'> $connected </span>"


	click_action+="\<b>$wlan_icon_colored$wlan_output Modul WLAN</b>  Help

    click left  $wlan_icon_colored: connect/disconnect
    click right $wlan_icon_colored: $(get_module_clicks wlan_right)
dbl click left  $wlan_icon_colored: $(get_module_clicks wlan_dbl_left)
dbl click right $wlan_icon_colored: $(get_module_clicks wlan_dbl_right)

dbl click left on $wlan_output for Info box
"

	notify-send -h string:x-dunst-stack-tag:module_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

# Main Execution 
on_click
