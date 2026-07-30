#!/bin/bash

# Maintenance procedures for EMC_standalone_app_installer: 
#
#		run_task, update_pkg, 
#		measure_apt_cache, rebuild_apt_cache, check_apt_cache
#		run_maintenance
#
# DEBIAN VERSION

#use this procedure for different tasks like autoclean fixbroken ...
run_task() {

	local task="$1" exec_task="false"
	local yad_exitcode task_log now

	now=$(date -R)
	f_task_log=$(mktemp)
	trap 'rm -f "$f_task_log"' RETURN

	case "$task" in
		"autoremove" )
		printf "%s\n\n" "### running apt $task ###" >> "$f_task_log"
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt $task  2>&1 | tee -a "$f_task_log" | dlg_mtsim "$task" ;;
		"fixbroken" )
		printf "%s\n\n" "### running apt --fix-broken install ###" >> "$f_task_log"
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt --fix-broken install  2>&1 | tee -a "$f_task_log" | dlg_mtsim "$task" ;;
	esac

	yad_exitcode=$?
	[ $yad_exitcode = $yad_remove ] && exec_task="true"	

	if [ "$exec_task" = "false" ]; then
		printf "\n%s\n" "$task aborted" >> "$f_task_log"
		printf "%\ns\n\n" "### all done ###" >> "$f_task_log"
		task_log=$(cat "$f_task_log")
		show_log "$task" "$task_log"
		return
	fi

	{ 
	case "$task" in
		"autoclean" | "clean")
		printf "%s\n\n" "### running apt $task ###" >> "$f_task_log"
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt $task  2>&1 | tee -a "$f_task_log"
		task_log=$(cat "$f_task_log") ;;
		"autoremove" )
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt $task -y 2>&1 ;;
		"fixbroken" )
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt --fix-broken -y install  2>&1 ;;
	esac
		echo -e "\n$task done" 
	} | dlg_maintenance_progress "$task"

	printf "\n%s\n\n" "### $task done ###" >> "$f_task_log"
	task_log=$(cat "$f_task_log")
	show_log "$task" "$task_log"
}

update_pkg() {

	local upgrade_now="false" list_upgradable="false" log_content=""
	local update_log=$(mktemp) upgrade_log=$(mktemp) exit_upgrade now

	now=$(date -R)
	printf "%s\n\n" "### running apt update $now ###" > "$update_log"

	# Execute apt update, tee -a append to update_log
	{
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt update 2>&1 | tee -a "$update_log"
		echo -e "\napt update done" 
	} | dlg_update


	# Execute upgrade
	echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt upgrade 2>&1 | tee "$upgrade_log" | dlg_upgrade

	exit_upgrade=$?

	now=$(date -R)
	printf "\n\n%s\n" "### running apt upgrade $now ###" >> "$update_log"
	cat "$upgrade_log" >> "$update_log"
	#log_content=$(< $update_log)
	log_content=$(grep -v -E "\[sudo\]|WARNING:|Use with caution" "$update_log")
	rm "$update_log" "$upgrade_log"

	if [ $exit_upgrade -ne $yad_upgrade ]; then
		show_log "Upgrade" "$log_content"
		return
	fi

	{ 
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt upgrade -y 2>&1
		echo -e "\ndone" 
	} | dlg_upgrade_progress

	show_log "Upgrade" "$log_content"

}

measure_apt_cache() {
	# We measure the time for a standard query
	local start_ms end_ms duration

	# Get start time in milliseconds
	start_ms=$(date +%s%3N)

	# Perform a silent test query
	apt-cache show bash > /dev/null 2>&1

	# Get end time
	end_ms=$(date +%s%3N)
	duration=$((end_ms - start_ms))

	echo "$duration"
}

rebuild_apt_cache() {

	local restart="${1:-""}"
	local suffix="RESTART script!"
	[ -n "$restart" ] && suffix=""

	# Rebuilding the cache requires root privileges
	[ -z "$EMC_passwd" ] && get_passwd "rebuild cache"
	if [ -z "$EMC_passwd" ]; then
		dlg_msg_box  "Password error" " ⚠️ Cannot rebuilt Cache. $suffix"
	else 
		notify-send -r $NOTIFY_ID -t 3000 "⏳ Check apt cache" "This may take a while ..."
		if echo "$EMC_passwd" | LC_ALL=C sudo -S sh -c "rm -f /var/cache/apt/*.bin && apt-get check && apt-get update" > /dev/null 2>&1; then
			duration="$(measure_apt_cache)"
			dlg_msg_box  "Cache rebuilt" " ✅ Cache rebuilt done  - duration: $duration ms. $suffix"
		else
			dlg_msg_box  "Cache rebuilt" " ❌ Cache rebuilt failed. $suffix"
		fi
	fi
}

check_apt_cache() {

	local maintenance="${1:-""}"
	local yad_exitcode duration="$(measure_apt_cache)"

	# Threshold: 500ms is already slow, 1000ms is critical
	if [ "$duration" -gt 250 ]; then
		dlg_check_apt_cache "$duration"
		yad_exitcode=$?

		if [ $yad_exitcode -eq $yad_ok ]; then
			rebuild_apt_cache
		else
			dlg_msg_box  "Cache corrupt" " ⚠️ Cannot run script with bad cache. Restart script to fix this problem." 450
		fi

		exit
	else
		[ -n "$maintenance" ] && return
		dlg_yesno_box "Check apt cache" " ✅ Cache ok - duration: $duration ms. Rebuild Cache anyway?"
		yad_exitcode=$?
		[ $yad_exitcode -eq $yad_ok ] && rebuild_apt_cache "no_restart"
	fi
}

# run selected maintenance task
run_maintenance() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot run Service while another task is running " && return

	touch "$APPINSTALLER_LOCK"
	trap 'rm -f "$APPINSTALLER_LOCK"' RETURN EXIT SIGINT SIGTERM
	#trap 'rm -f "$APPINSTALLER_LOCK"; check_focus' RETURN EXIT SIGINT SIGTERM

	local choice yad_exitcode

	choice="$(dlg_maintenance)"

	yad_exitcode=$?

	[ $yad_exitcode = $yad_cancel ] && return
	[ "$choice" = "(null)" ] && return
#notify-send "EMC Debug" "Choice: '$choice' (Length: $(echo -n "$choice" | wc -c))"
	[ -z "$EMC_passwd" ] && get_passwd "$choice"
	[ -z "$EMC_passwd" ] && return

	case "$choice" in
		"update") update_pkg ;;
		"autoclean" | "autoremove" | "fixbroken" | "clean") run_task "$choice" ;;
		"check apt cache") check_apt_cache ;;
	esac

	restore_selection
	

}
