#!/bin/bash

# This is the event handler for [module/screenshot]

#notify-send "screenshot_event_handler:script started"

# Input arguments
BUTTON="$1"     # "left", "right"
WS_NAME="$2"    # Optional context (workspace name)

# same as in ~/.config/i3/script/printscreen.sh
readonly NOTIFY_ID=1002
readonly NOTIFY_TIME=2500

readonly NOTIFY_ID_H=200

# Procedure: on_single_click 
on_click() {
case $BUTTON in
	# edit this begin
	left)		printscreen;;
	dbl_left)	printscreen p;;
	right)		eval $(exec_key screenshot_right) &;;
	dbl_right)	eval $(exec_key screenshot_dbl_right) &;;
	up)			show_screenshot_click_actions ;;
	down)		dunstctl close $NOTIFY_ID_H ;;
	# edit this end
esac
}

# Procedure: printscreen 
printscreen() {
	local PIC_DIR PIC_FILE

	PIC_DIR="$HOME/Pictures"
	PIC_FILE="$PIC_DIR/screenshot_$(date +%Y-%m-%d_%H:%M:%S).png"

	# creates the folder if it does not exist
	mkdir -p "$PIC_DIR"

	# for screenshot without cursor use the -u option: maim -u "$filename" 
	case "$1" in
		# p(artial) selects the screen area
		"p") maim -s "$PIC_FILE";;
		# fullscreen
		"")   maim "$PIC_FILE";;
		"right") eval $(exec_key keyboard_right) &;;
		"dbl_right") eval $(exec_key keyboard_dbl_right) &;;
	esac

	notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "Screenshot stored in $PIC_FILE"
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

show_screenshot_click_actions() {

	# colors from polybar config.ini
	local color_primary="#F0C674" color_bg="#282A2E"
	local click_action="" screenshot_icon=""
	local screenshot_icon_colored="<span background='$color_bg' foreground='$color_primary'>$screenshot_icon</span>"


	click_action+="\<b>$screenshot_icon_colored Modul SCREENSHOT</b>  Help

    click left  $screenshot_icon_colored: full    screenshot
dbl click left  $screenshot_icon_colored: partial screenshot
    click right $screenshot_icon_colored: $(get_module_clicks screenshot_right)
dbl click right $screenshot_icon_colored: $(get_module_clicks screenshot_dbl_right)

Press         [Print Screen] for full    screenshot
Press [Win] + [Print Screen] for partial screenshot
"

	notify-send -h string:x-dunst-stack-tag:module_h -r $NOTIFY_ID_H "" "<tt>$click_action</tt>"
}

# Main Execution 
on_click

