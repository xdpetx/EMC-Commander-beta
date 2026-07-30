#!/bin/bash

# Dialogs run procedures for EMC_standalone_app_installer:
#
#	get_passwd, get_install_state, clear_selection, restore_selection
#	show_log, save_log
#
#	run_system_report, run_pkg_search
#	run_main_dlg
#
# DEBIAN VERSION

get_passwd() {

	local action="$1" passwd="" trial exitcode

	for trial in 1 2 3; do

		passwd="$(dlg_get_password "$action" $trial)"

		exitcode=$?
		[ $exitcode -ne $yad_ok ] && return

		if [ -z "$passwd" ]; then
			notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "password empty try again"
			exitcode=1
			continue
		fi

		# -k ignore cache !
		# fast passwd check: timeout 0.5s
		printf "%s\n" "$passwd" | timeout 0.5s sudo -S -k true 2>/dev/null
		exitcode=$?
		if [ $exitcode -ne 0 ]; then
			notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "wrong password try again"
			passwd=""
		else
			break
		fi
	done

	if [ $exitcode -ne 0 ]; then
		dlg_password_error "$action"
	fi

	EMC_passwd="$passwd"
	
	# save to file otherwise passwd will be lost in subshell!
	echo "$passwd" > "$TMP_passwd"
}

get_install_state() {
	
	local i pkg install_state
	
	for ((i=1; i<${#DLG_APPS[@]}; i+=$DLG_COLS)); do
		# package name is in  field i
		pkg="${DLG_APPS[$i]}"
		[[ -z "$pkg" || "$pkg" == "(null)" ]] && continue
		install_state=$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null)
		if [[ "$install_state" == "install ok installed" ]]; then
			DLG_APPS[$((i+3))]="INSTALLED"
			DLG_APPS[$((i-1))]="FALSE"
		else
			DLG_APPS[$((i+3))]=""
		fi
	done
}

clear_selection() {
	
	local i num_apps=${#DLG_APPS[@]}
	
	# reset selection for all apps to FALSE
	for ((i=0; i<$num_apps; i+=$DLG_COLS)); do
		DLG_APPS[$i]="FALSE"
	done
}

restore_selection() {
	local sel pkg j install_state pkg_name
	# step 1: reset selection for all apps to FALSE
	clear_selection
	
	# step 2: set selected apps to TRUE
	while IFS='|' read -r sel pkg _; do
		[ -z "$pkg" ] && continue

		for ((j=1; j<${#DLG_APPS[@]}; j+=$DLG_COLS)); do
			pkg_name="${DLG_APPS[$j]}"
			install_state="${DLG_APPS[$((j+3))]}"
						
			if [[ "$pkg_name" == "$pkg" ]]; then
				#[ "$install_state" = "INSTALLED" ] && continue
				# Once we've found the name, the status is
				# exactly one field BEFORE (j-1)
				DLG_APPS[$((j-1))]="$sel"
				break
			fi
		done
	done <<< "$DLG_SELECTION"
}

show_log() {

	local title="$1" logcontent="$2" yad_exitcode=0

	[ -n "$logcontent" ] && echo -e "$logcontent" | dlg_show_log

	yad_exitcode=$?

	if [ $yad_exitcode -eq $yad_save ]; then
		local now=$(date +%s)
		local logfile
		logfile="$HOME/.config/polybar/log/emc_app_installer_${title}_${now}.log.txt"
		save_log "$logfile" "$logcontent"
	fi
}

save_log() {

	local logfile="$1" logcontent="$2" yad_exitcode

	echo "save_log: logfile = $logfile" >&2

	logfile="$(dlg_save_log "$logfile")"
	yad_exitcode=$?

	if [ $yad_exitcode -eq $yad_ok ] && [ -n "$logfile" ]; then
		mkdir -p "$(dirname "$logfile")"
		echo -e "$logcontent" > "$logfile"
		notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "ℹ️ Log saved to" "\n<tt>$logfile</tt>"
	fi	
}

run_system_report() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot check system while another task is running " && return

	touch "$APPINSTALLER_LOCK"
	trap 'rm -f "$APPINSTALLER_LOCK"' RETURN EXIT SIGINT SIGTERM

	local os_release disk_space pkg_installed gtk_lib qt_lib kde_lib
	local mem_free proc_state apt_cache_time syslog=""
	local now=$(date -R)

	check_inet

	os_release=$(cat /etc/os-release)
	disk_space=$(LC_ALL=C df -h / "$HOME" "$(dirname "$0")")
	pkg_installed=$(LC_ALL=C dpkg -l | grep '^ii' | wc -l)
	gtk_lib=$(dpkg -l | grep "libgtk")
	qt_lib=$(dpkg -l | grep "libqt")
	kde_lib=$(dpkg -l | grep "libkde")
	mem_free=$(LC_ALL=C free -hltw)
	proc_state=$(LC_ALL=C ps -eo pcpu,pmem,comm --sort=-pcpu | head -n 11)
	apt_cache_time=$( { TIMEFORMAT="real: %R\nuser: %U\nsys : %S"; time apt-cache show bash > /dev/null; } 2>&1 )

	syslog="$(txt_syslog)"

	show_log "System report" "$syslog"
}

run_clear_selection() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot clear selection while another task is running " && return

	touch "$APPINSTALLER_LOCK"
	trap 'rm -f "$APPINSTALLER_LOCK"' RETURN EXIT SIGINT SIGTERM

	clear_selection
}

run_download_speed() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot measure download speed while another task is running " && return

	touch "$APPINSTALLER_LOCK"
	trap 'rm -f "$APPINSTALLER_LOCK"' RETURN EXIT SIGINT SIGTERM

	{ 
		check_download_speed
		echo -e "\nDOWNLOAD_SPEED = $DOWNLOAD_SPEED\n"
		echo "    DSL  6.000 = 0.75 MB/s"
		echo "    DSL 16.000 = 2.0  MB/s"
		echo "   VDSL 50.000 = 6.0  MB/s"
		echo -e "\ndone"
	} | dlg_show_progress "download speed" "" "$i_sysrun"

}

run_pkg_search() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot run package search while another task is running " && return
	touch "$APPINSTALLER_LOCK"

	local f_installed_pkgs=$(mktemp) 
	local f_found_pkgs=$(mktemp)
	local f_yad_selection=""

	# only one trap per scope
	trap 'rm -f "$APPINSTALLER_LOCK" "$f_installed_pkgs" "$f_found_pkgs" "$f_yad_selection"' RETURN EXIT SIGINT SIGTERM

	local search_pkg="$(dlg_get_pkg "search")"
	[ -z "$search_pkg" ] && return

	local search_list=() search_dlg_selection yad_exitcode 
	local num_pkg=0 num_installed=0 install_state desc max_pkg=500

	#local -r yad_install=10 
	local -r l_yad_remove=20
	local -r state_installed="Installed"
	local -r state_not_installed="Not installed"

	dpkg-query -W -f='${Package}\n' > "$f_installed_pkgs"
	grep -h "^Package: .*$search_pkg" /var/lib/apt/lists/*_Packages | cut -d' ' -f2- | sort -u > "$f_found_pkgs"
	num_pkg=$(wc -l < "$f_found_pkgs")
	if [ $num_pkg -gt $max_pkg ]; then
		dlg_msg_box "" "Too many matches for <span foreground='#FF0000'>$search_pkg</span>: $num_pkg found. Maximum is $max_pkg"
		return
	elif [ $num_pkg -eq 0 ]; then
		dlg_msg_box "" "package <span foreground='#FF0000'>$search_pkg</span> - no matches"
		return
	elif [ $num_pkg -gt 200 ]; then
		notify-send -r $NOTIFY_ID -t 3000 "⏳ search $num_pkg pgks" "This may take a while ..."
	fi

	if [ ! -s "$SEARCH_DESCRIPTIONS" ]; then
		notify-send -r $NOTIFY_ID -t 3000 "ℹ️ looking for descriptions" "This may take a while ..."
		awk '/^Package: / {p=$2} /^Description: / {sub(/^Description: /, ""); print p "|" $0}' /var/lib/apt/lists/*_Packages > "$SEARCH_DESCRIPTIONS"
	fi

#mapfile -t f_found_pkgs_array < <(apt-cache pkgnames | grep "$search_pkg" | sort)
#grep -Ff <(printf "%s\n" "${f_found_pkgs_array[@]}") "$SEARCH_DESCRIPTIONS" > "$tmp_mapping"

	while read -r pkg; do
		if fgrep -qxf "$f_installed_pkgs" <<< "$pkg"; then
			install_state="$state_installed"
			((num_installed++))
		else
			install_state="$state_not_installed"
		fi
		desc=$(grep -m1 "^$pkg|" "$SEARCH_DESCRIPTIONS" | cut -d'|' -f2-)
		[[ -z "$desc" ]] && desc="not available"

		search_list+=("FALSE" "$pkg" "$install_state" "$desc")
	done < <(apt-cache pkgnames | grep "$search_pkg")

	f_yad_selection=$(dlg_pkg_search "${search_list[@]}")
	yad_exitcode=$?

	[ $yad_exitcode -eq $yad_cancel ] && return

	[ -z "$EMC_passwd" ] && get_passwd "Search"
	[ -z "$EMC_passwd" ] && return

	INSTALLATION_RESULT=""

	local sel pkg state ifs_save="$IFS"

	while IFS='|' read -r sel pkg state _; do
		if [ "$sel" = "TRUE" ]; then
			if [ $yad_exitcode -eq $yad_full_install ]; then
				[ "$state" = "$state_not_installed" ] && install_pkg "$pkg"
			fi
			if [ $yad_exitcode -eq $l_yad_remove ]; then
				if [ "$state" = "$state_installed" ]; then
					dlg_msg_box "WARNING" "⚠️ CAUTION you may damage your system ⚠️️️️️️\n\nexamine simulation result for <span foreground='#FF0000'>$pkg</span> carefully before remove"
					remove_pkg "$pkg"
				fi
			fi
		fi
	done < "$f_yad_selection"

	IFS="$ifs_save"

	show_log "Install" "$INSTALLATION_RESULT"
	get_install_state
}

run_send_feedback() {

	$_SCRIPTDIR/send_feedback.sh
}

run_exit_appinstaller() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot exit app installer while another task is running " && return

	exit
}

run_main_dlg() {

	local yad_exitcode

	while true; do

		dlg_main
		yad_exitcode=$?

		# has user entered  password?
		if [ -s "$TMP_passwd" ]; then
			EMC_passwd=$(cat "$TMP_passwd")
			# clear file, password is saved now
			> "$TMP_passwd"
		fi

		case "$yad_exitcode" in
			1 | 252) run_exit_appinstaller;;
			10) run_clear_selection &;;
			20) run_installation &;;
			30) run_remove &;;
			40) run_pkg_search &;;
			50) run_system_report &;;
			60) run_maintenance &;;
			70) run_download_speed &;;
			80) run_send_feedback &;;
		esac
	done
}
