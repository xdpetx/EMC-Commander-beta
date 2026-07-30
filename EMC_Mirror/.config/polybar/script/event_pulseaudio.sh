#!/bin/bash

# This is the event handler for [module/pulseaudio]

#notify-send "pulseaudio_event_handler:script started"

# Input arguments
BUTTON=$1     # "left", "right"
WS_NAME=$2    # Optional context (workspace name)

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=2500

readonly NOTIFY_ID_H=200

# Procedure: on_click 
on_click() {
case $BUTTON in
	left	 ) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
	right	 ) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
	# edit this begin
	dbl_left ) eval $(exec_key pulseaudio_dbl_left) & ;;
	dbl_right) eval $(exec_key pulseaudio_dbl_right) & ;;
	up		 ) show_pulseaudio_click_actions ;;
	down	 ) dunstctl close $NOTIFY_ID_H ;;
	# edit this end
esac
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

function audio_nmuted() {

	local muted=$(LC_ALL=C pactl get-sink-mute @DEFAULT_SINK@)
	muted=${muted#* }

	[ "$muted" = "yes" ] && return 0

	return 1
}

show_pulseaudio_click_actions() {

	# colors from polybar config.ini
	local color_primary="#F0C674" color_bg="#282A2E" color_fg="#C5C8C6" color_disabled="#707880"
	local click_action="" pulseaudio_icon=""
	local pulseaudio_icon_colored="<span background='$color_bg' foreground='$color_primary'>$pulseaudio_icon</span>"
	local pulseaudio_icon_disabled="<span background='$color_bg' foreground='$color_disabled'>$pulseaudio_icon</span>"
	local pulseaudio_output="<span background='$color_bg' foreground='$color_fg'> 100% </span>"


	# be careful if you change fg for [module_h] in dunst.rc !
	local color_enabled="#222222"
	! audio_nmuted && color_disabled="$color_enabled"
	! audio_nmuted && pulseaudio_icon_disabled="$pulseaudio_icon_colored"

	click_action+="\<b>$pulseaudio_icon_colored$pulseaudio_output Modul PULSEAUDIO</b>  Help

    click left  $pulseaudio_icon_colored: audio on/off
    click right $pulseaudio_icon_colored: micro on/off<span foreground='$color_disabled'>
dbl click left  $pulseaudio_icon_disabled: $(get_module_clicks pulseaudio_dbl_left)
dbl click right $pulseaudio_icon_disabled: $(get_module_clicks pulseaudio_dbl_right)</span>

    scroll        on $pulseaudio_output for volume

    click left/right on $pulseaudio_output show/hide Info
dbl click left       on $pulseaudio_output open Info box
"
	notify-send -h string:x-dunst-stack-tag:module_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

# Main Execution 
on_click
