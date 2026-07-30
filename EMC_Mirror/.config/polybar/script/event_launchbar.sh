#!/bin/bash

# This is the event handler for the launchbar - no dblclicks processed

#notify-send "launchbar_event_handler:script started"

# Input arguments
APP_KEY="$1"    # the key from application.ini
BUTTON="$2"     # "left", "right"
APP=""			# the value for APP_KEY

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=2500

# Procedure: get_app 
# load users app from applications.ini
get_app() {
	local APP_INI APP_CONTENT key

	APP_INI="$_USERDIR/applications.ini"
	APP_CONTENT=$(cat "$APP_INI")
	
	# Parse applications.ini using pure bash parameter expansion for performance
	while IFS='=' read -r key APP; do
		key=${key%% *}
		if [ "$key" = "$APP_KEY" ]; then break; fi
	done <<< "$APP_CONTENT"
}

# Procedure: exec_app 
# exec users app from applications.ini
exec_app() {
	# remove all occurrences of \r
	APP="${APP//$'\r'/}"
	# Remove leading whitespace (nested parameter expansion)
	APP="${APP#${APP%%[![:space:]]*}}"
	# Remove trailing whitespace (nested parameter expansion)
	APP="${APP%${APP##*[![:space:]]}}"

	if [ -z "$APP" ]; then
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ EMC Warning" "\non-click $APP_KEY: No command defined in applications.ini"
		return
	else 
		# Remove quotes ONLY if they enclose the ENTIRE string
		if [[ "$APP" == \"*\" ]]; then
			APP="${APP#\"}"
			APP="${APP%\"}"
		elif [[ "$APP" == \'*\' ]]; then
			APP="${APP#\'}"
			APP="${APP%\'}"
		fi
	fi
	APP="${APP%&}"

	local CMD=${APP%% *}
	local EXPANDED_CMD=$(eval echo "$APP")
	#notify-send "Debug" "\nCMD: #$CMD#\nEXPANDED_CMD: #$EXPANDED_CMD#\nAPP: #$APP#"
	# STEP 1: Check only the binary ($cmd). Quotes ("$cmd") prevent issues with spaces in paths and treat the binary as one single file.
	if ! command -v "$CMD" >/dev/null 2>&1; then
		# is $APP a script?
		if [ -x "$EXPANDED_CMD" ]; then
			eval "$APP" &
			return
		fi
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ EMC Warning" "\n$APP_KEY = $CMD: application is not installed"
		return
	# STEP 2: Check the full command string ($app) WITHOUT quotes. No quotes allow 'word splitting', so 'command -v' can separate 
	# the binary from its arguments (e.g., -r). Using quotes here would incorrectly search for a filename containing spaces/args.
	#elif ! command -v $APP >/dev/null 2>&1; then
	elif ! bash -n <<< "$APP" >/dev/null 2>&1; then
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ EMC Warning" "\n$APP_KEY = $APP: invalid command in applications.ini"
		return
	fi

	# Directly evaluate the string as a command and push to background.
	eval "$APP" &
}

# Main Execution 
get_app
exec_app
