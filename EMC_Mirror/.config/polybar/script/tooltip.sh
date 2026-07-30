#!/bin/bash

# Tooltip script with aggressive cleanup to prevent freezing
PIDFILE="/tmp/polybar_tooltips.pid"
TOOLTIP_FILE="/tmp/polybar_tooltip"
TOOLTIP_KEY="$1"
SCROLL_KEY="$2"

# Determine location based on running instances
if pgrep -f "polybar launchbar_left" > /dev/null; then
    LOCATION="l"
elif pgrep -f "polybar launchbar_right" > /dev/null; then
    LOCATION="r"
else
    LOCATION="c"
fi

get_tooltip(){

	local TOOLTIP_INI TOOLTIP_VALUE key value
	
	# Path to the user-editable tooltip file
	TOOLTIP_INI="$HOME/.config/polybar/usr/tooltips.ini"

	# Fetch the value
	if [[ "$TOOLTIP_KEY" =~ ^t_ ]]; then

		while IFS='=' read -r key value; do
			key=${key%% *}
			if [ "$key" = "$TOOLTIP_KEY" ]; then 
				# Remove leading whitespace (nested parameter expansion)
				value="${value#${value%%[![:space:]]*}}"
				# Remove trailing whitespace (nested parameter expansion)
				value="${value%${value##*[![:space:]]}}"
				if [ -z "$value" ]; then
					TOOLTIP_VALUE="not implemented"
				else
					TOOLTIP_VALUE="$value"
				fi
					break
			fi
		done < "$TOOLTIP_INI"

	else
		TOOLTIP_VALUE="$TOOLTIP_KEY"
	fi

	# If TOOLTIP_VALUE is "not implemented", it is NOT empty, so it will be shown.
	if [[ -n "$TOOLTIP_VALUE" ]]; then
		case "$SCROLL_KEY" in
			"up")   echo "click left: $TOOLTIP_VALUE" > /tmp/polybar_tooltip;;
			"down") echo "click right: $TOOLTIP_VALUE" > /tmp/polybar_tooltip;;
			*)      echo "$TOOLTIP_VALUE" > /tmp/polybar_tooltip;;
		esac
	fi
}

show_tooltip() {
    # 1. Kill any existing tooltip bars before starting a new one
    # This prevents multiple tooltip bars from stacking up
    pkill -f "polybar tooltips_" 2>/dev/null

    # 2. Start the new tooltip bar
    case "$LOCATION" in
        "l" | "left") polybar tooltips_left & ;;
        "r" | "right") polybar tooltips_right & ;;
        *) polybar tooltips_center & ;;
    esac

    # 3. Save PID of the newly started bar
    echo $! > "$PIDFILE"

    # 4. Wait and cleanup
    sleep 1.5
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
}

# Use a lock mechanism to ensure only one instance of show_tooltip runs
if [ ! -f "$PIDFILE" ]; then

	# Define the lock directory
	LOCK_DIR="/tmp/polybar_scroll.lock"

	# Try to create the directory
	if mkdir "$LOCK_DIR" 2>/dev/null; then
		# Set the trap to clean up on exit, error, or interruption
		trap 'rmdir "$LOCK_DIR"' EXIT SIGINT SIGTERM

		# Run the tooltip. We don't use '&' here so the 
		# script stays alive for the duration of the lock
		get_tooltip
		show_tooltip 

		# Extra buffer to ignore rapid scroll events
		sleep 0.1
	else
		# Silent exit if the lock is already held by another process
		exit 0
	fi

fi

exit
