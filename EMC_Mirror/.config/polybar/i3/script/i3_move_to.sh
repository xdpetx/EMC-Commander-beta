#!/bin/bash

# call with move_to.sh window|container

PARAM=$1
CONFIG_FILE="$HOME/.config/i3/usr/config_workspaces"
PID_FILE="/tmp/polybar_move_to.pid"
WS_LIST=()

# start only one instance
if [ -f "$PID_FILE" ]; then
	notify-send -t 1500 "move_to.sh: just running. can't start another instance"
	exit
else
	# $$ PID of this script
	echo $$ > "$PID_FILE"
fi

# change layout when moving windows for better selection
#if [ $PARAM = "window" ]; then
#	i3-msg "layout stacking"
#fi

# read the config file and setup WS_LIST
while read -r set ws_num ws_name; do
    # a valid line begins with set
    if [ "$set" = "set" ]; then 
		# Use ws_name for the first column (workspace:TEXT)
		WS_LIST+=("$ws_name")
		# Use ws_num for the second column (description:TEXT)
		WS_LIST+=("move to workspace $ws_num")
	fi
done < "$CONFIG_FILE"

# dialog size and position begin
case "$PARAM" in
	container) title=" move workspace to";;
	*) title=" move $PARAM to";;
esac
height=350
width=310
# dialog size and position end

# now call the dialog
retval=$(yad --list \
--title="$title" \
--window-icon=system-run \
--text="Select a workspace to move to" \
--column="workspace:TEXT" \
--column="description:TEXT" \
--item-type=1 \
--width="$width" \
--height="$height" \
--center \
--button="move"\!gtk-ok \
--button="cancel"\!gtk-cancel \
--buttons-layout center \
"${WS_LIST[@]}")

TARGET_WS=${retval%%|*}

case "$TARGET_WS" in

    "(null)"|"") : ;;
    *)
      if [ "$TARGET_WS" != "" ]; then
            if [ "$PARAM" = "container" ]; then
                i3-msg "focus parent" 
            fi
        i3-msg "move $PARAM to workspace $TARGET_WS"
		i3-msg "workspace number $TARGET_WS"
      fi
      ;;
      
esac

rm -f "$PID_FILE"

exit 0
