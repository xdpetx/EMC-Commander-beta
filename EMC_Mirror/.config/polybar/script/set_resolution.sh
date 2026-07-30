#!/bin/bash

TITLE=""
RESOLUTION=""
MONITOR=""
DLG_LIST=()
PID_FILE="/tmp/polybar_set_resolution.pid"

readonly INSTANCE="EMC_Set_Resolution"

# start only one instance
if [ -f "$PID_FILE" ]; then
	notify-send -t 1500 "set_resolution.sh: just running. can't start another instance"
	exit
else
	# $$ PID of this script
	echo $$ > "$PID_FILE"
fi

#greatest common divisor
function gcd() {
	local a=$1 b=$2
	while [ $b -ne 0 ]; do
		local t=$b
		b=$((a % b))
		a=$t
	done
	echo $a
}

# Function to return standardized ratios with modulo-based rounding
function getratio() {
	local width height res GCD
	
	res="$1"
	width=${res%x*}
	height=${res#*x}

	# Calculate ratio * 10 (e.g., 1.77 becomes 17)
	local val=$(( width * 10 / height ))
	# Get the remainder (modulo) to decide whether to round up
	local rem=$(( (width * 100 / height) % 10 ))

	# If remainder is 5 or higher, round up the main value
	if [ "$rem" -ge 5 ]; then
		((val++))
	fi

	# Now 'val' is a rounded representation (18 for 16:9, 16 for 16:10)
	case "$val" in
		18) echo "16:9" ; return ;;
		16) echo "16:10" ; return ;;
		13) echo "4:3" ; return ;;
		12) echo "5:4" ; return ;;
	esac

	# Fallback to exact mathematical GCD
	GCD=$(gcd "$width" "$height")
	echo "$((width / GCD)):$((height / GCD))"
}

getresolution(){
	# save entire output of xrandr
	retval=$(xrandr)

	while read -r res val _; do
		[[ "$val" == "connected" ]] && MONITOR="$res"
		if [[ $res =~ ^[0-9] ]]; then
			DLG_LIST+=("$res")
			ratio=$(getratio "$res")
			DLG_LIST+=("$ratio")
		fi
	done <<< "$retval" 

}

show_monitor_dialog() {

local dlg_btn=(
--button=" APPLY!emc-gtk-apply:0" \
--button=" CANCEL!emc-gtk-cancel:1"
)

RESOLUTION=$(yad --name="$INSTANCE" \
--list \
--title="$TITLE" \
--window-icon="emc-display" \
--column="Resolutions" \
--column="Ratio" \
--print-column=1 \
--height=300 \
"${dlg_btn[@]}" \
"${DLG_LIST[@]}")

exitcode=$?
RESOLUTION=${RESOLUTION%%|}
}

getresolution
TITLE="$MONITOR Set resolution"

# first close all Info and Help notifies
dunstctl close-all

# yad dialog for selecting screen resolution
# “OK” applies AND saves. “Cancel” exits.
show_monitor_dialog
if [ "$exitcode" = "0" ]; then
	# OK was clicked - apply RESOLUTION
	xrandr --output "$MONITOR" --mode "$RESOLUTION"
	eval "$_BASEDIR/launch.sh i3"
fi

rm -f "$PID_FILE"

exit
