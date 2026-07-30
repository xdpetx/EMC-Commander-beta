#!/bin/bash

# Path to your workspace configuration
WS_CONFIG="$HOME/.config/i3/usr/config_workspaces"

# The target key we are looking for (e.g., "$ws1" or "$ws10")
# We prefix the passed argument with '$ws'
TARGET_KEY="\$ws$1"
TARGET_SCRIPT="$2"
WS_NAME=""
WS_ICON=""

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=1500

get_ws_name() {
# Read the config file line by line
while read -r cmd wskey wsname; do
	# Check if cmd is a comment
	[[ -z "$cmd" || "$cmd" == \#* ]] && continue
    # Check if the current line defines the key we need (e.g., $ws1)
    if [[ "$wskey" == "$TARGET_KEY" ]]; then
        # Remove quotes using parameter expansion - no external processes needed
        # tmpval removes the trailing quote, WS_NAME removes the leading quote
        tmpval=${wsname%\"}
        WS_NAME=${tmpval#\"}
        WS_ICON=${WS_NAME#*:}
#notify-send "cmd: *$cmd* WS_NAME: #$WS_NAME# WS_ICON: #$WS_ICON#"
        break
    fi
done < "$WS_CONFIG"
}

run_start_script() {
	local APP_FILE CMD EXPANDED_CMD cmd title="Start script workspace"

	[[ -z "$TARGET_SCRIPT" ]] && return

	APP_FILE="$HOME/.config/polybar/usr/applications.ini"

	# Extract path and expand shell variables like $_USERSCRIPT
	CMD=$(grep "^$TARGET_SCRIPT =" "$APP_FILE" | cut -d'=' -f2- | xargs)

	if [[ -n "$CMD" ]]; then
		EXPANDED_CMD=$(eval echo "$CMD")

		# Check if it is an executable script or a command
		if [ ! -x "$EXPANDED_CMD" ]; then
			cmd=${EXPANDED_CMD%% *}

#notify-send "Debug" "Content of cmd: #$cmd# EXPANDED_CMD: #$EXPANDED_CMD# CMD: #$CMD#"
			if ! command -v "$cmd" >/dev/null 2>&1; then
				notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "❕$title $WS_ICON" "\n$TARGET_SCRIPT = $EXPANDED_CMD: no such command found"
				return
			fi
		fi

		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "$title $WS_ICON" "\nLaunching: $EXPANDED_CMD"
		$EXPANDED_CMD &
	else
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "❕$title $WS_ICON" "\n$TARGET_SCRIPT = : no start script or command defined in applications.ini"
	fi
}

open_ws() {
# If found, switch to it; otherwise fallback to the index
if [[ -n "$WS_NAME" ]]; then
	local INIT_FLAG is_opened
	
	INIT_FLAG="/tmp/i3_ws_first_run"
	
	# Use --arg to pass the bash variable into jq and any() for boolean output
	is_opened=$(i3-msg -t get_workspaces | jq --arg val "$WS_NAME" 'any(.[] ; .name == $val)')
	i3-msg workspace "$WS_NAME"
	# if not run startscript
	if [ "$is_opened" = "false" ]; then 
		run_start_script
	elif [ ! -f "$INIT_FLAG" ]; then
		# First run after login (covers the pre-existing Home WS)
		touch "$INIT_FLAG"
		run_start_script
	fi
else
	# Fallback to the raw index passed from Polybar
	i3-msg workspace "$1"
fi
}

get_ws_name
open_ws

exit

