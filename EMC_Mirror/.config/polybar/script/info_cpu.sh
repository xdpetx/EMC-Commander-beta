#!/bin/bash

#notify-send "info_cpu.sh: sript started"

source "$_SCRIPTDIR/info_box.sh"

BUTTON="$1"
CPU_INFO=""
CPU_ICON=""

readonly NOTIFY_ID_I=100

get_cpu_state() {

	local line key fmt load_1 load_5 load_15 cpu_state=""
	
	while read -r line; do
	
		IFS=':' read -r key val <<< "$line"
		key="${key%"${key##*[![:space:]]}"}"
		
		case "$key" in
			"processor")
				processor="${val//[[:space:]]/}"
				if [ "$processor" = "0" ]; then
					proc_line="$line\n"
				else
					cpu_state+="$line\n"
				fi
				;;
			"model name")
			if [ "$processor" = "0" ]; then 
				cpu_state+="manufacturer    :$val\n\n"
				cpu_state+="$proc_line"
			fi
			;;
			"cpu MHz")
				cpu_state+="$line\n"
			;;
			"cache size")
				cpu_state+="$line\n\n"
			;;

		esac
		
	done < /proc/cpuinfo

	temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
	gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
	max_f=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq) / 1000 ))

	# Extract  the 1, 5, and 15 minute load averages and threads
	read -r load_1 load_5 load_15 threads lastpid< /proc/loadavg

	# Fixed width of 24 characters for the key
	fmt="%-24s: %s\n"

	cpu_state+=$(printf "$fmt" "Temperature" "${temp}°C")"\n"
	cpu_state+=$(printf "$fmt" "System Load (1/5/15 min)" "$load_1/$load_5/$load_15")"\n"
	cpu_state+=$(printf "$fmt" "System Threads run/all" "$threads")"\n"
	cpu_state+=$(printf "$fmt" "Governor" "$gov")"\n"
	cpu_state+=$(printf "$fmt" "Max Takt" "$max_f MHz")

	echo "$cpu_state"
}

get_cpu_info() {
	local pango=0
	[ -z "$1" ] && pango=1

	local color_primary="#F0C674" cpu_icon="" header_cpu=""
	local colored_cpu_icon="<span foreground='$color_primary'>$cpu_icon</span>"

	[ $pango -eq 1 ] && header_cpu="<b>\
$colored_cpu_icon Modul CPU</b> Info <i>(click to close)</i>

"
	CPU_INFO="$header_cpu"
	CPU_INFO+="$(get_cpu_state)"$'\n'
}

if [ "$BUTTON" = "left" ]; then
	get_cpu_info
	notify-send -h string:x-dunst-stack-tag:module -r $NOTIFY_ID_I "" "<tt>$CPU_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
elif [ "$BUTTON" = "dbl_left" ]; then
	get_cpu_info nopango
	CPU_INFO=$(printf "\n%b" "$CPU_INFO")
	info_box "$CPU_ICON CPU Info box" "$CPU_INFO" 650 525
fi
