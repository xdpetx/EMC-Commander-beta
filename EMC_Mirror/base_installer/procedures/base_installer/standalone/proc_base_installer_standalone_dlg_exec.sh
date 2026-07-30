#!/bin/bash

# EMC_standalone_base_installer - dialog exec and run procedures:
#
#	run_test, usage, run_system_report, 
#	run_fm_selection, show_package_info,
#	exec_main_menu
#
#	save_log can_install 
#	do_simulate_install run_standalone_install_simulation
#	do_install run_standalone_installation
#
# DEBIAN VERSION

not_implemented() {

	local title="$1"
	
	msg_box "$title" "not implemented"
	return
}

show_help() {

	local info_txt

	if [ $MINIMAL_SYSTEM = "true" ]; then
		info_txt="$INSTALL_HELP"
	elif [ $INSTALL_SUCCESS = "true" ]; then
		info_txt="$POST_INSTALL_HELP"
	else
		info_txt="$PRE_INSTALL_HELP"
	fi

	full_text_box "HELP" "$info_txt"
}


show_description() {

	text_box "DESCRIPTION" "$DESCRIPTION_TXT" 35 125
}

show_readme() {

	show_log "README" "$INST_DIR/README_STANDALONE_INSTALL"
}

show_bash_history() {

	show_log "bash_history_template" "$INST_DIR/bash_history_template"
}

run_system_report() {

	local syslog="$(system_report)"

	full_text_box "System check" "$syslog"
}

run_reboot() {

	local can_reboot="true"

	if [ "$INSTALL_SUCCESS" = "false" ]; then
		can_reboot=""
	elif [ "$EMC_running" = "true" ]; then
		can_reboot=""
	else
		[ -z "$EMC_passwd" ] && get_passwd
		[ -z "$EMC_passwd" ] && can_reboot=""
	fi

	[ -z "$can_reboot" ] && return

	cleanup

	sync && sleep 2
	sudo -S <<< "$EMC_passwd" /sbin/reboot
}

run_fm_selection() {

	local selection=""

	selection=$(select_fm)

	if [ -n "$selection" ]; then
		selection="${selection//\"/}"
		FM_BASE=("$selection")
		INSTALL_PACKAGES=("${APT_BASE[@]}" "${X11_BASE[@]}" "${BLUETOOTH_BASE[@]}" "${PRINTER_BASE[@]}" "${SYSTEM_BASE[@]}" "${EMC_BASE[@]}" "${FM_BASE[@]}")
		INSTALL_PACKAGES_INSTALL_STATE=($(get_packages_install_state "${INSTALL_PACKAGES[@]}"))

		ALL_PACKAGES=("${APT_BASE[@]}" "${X11_BASE[@]}" "${BLUETOOTH_BASE[@]}" "${PRINTER_BASE[@]}" "${SYSTEM_BASE[@]}" "${EMC_BASE[@]}" "${FM_BASE[@]}")
	fi
}

remove_install_dir() {
	[ "$EMC_running" = "true" ] && return
	not_implemented "remove install directory"
}

show_download_speed() {

	get_download_speed && msg_box "" "$(msg_download_speed)" 15 40

}

show_package_info() {
	local pkg_info title

	pkg_info=$(get_standalone_package_info)
	title="Standalone package info"

	full_text_box "$title" "$pkg_info"
}

exec_main_menu() {

	local selection="$1" 

	case "$selection" in
		s) run_system_report ;;
		r) remove_install_dir ;;
		g) show_download_speed ;;
		f) run_fm_selection ;;
		p) show_package_info ;;
		d) run_standalone_download_simulation ;;
		D) run_standalone_download ;;
		i) run_standalone_install_simulation ;;
		I) run_standalone_installation ;;
		G) run_iso_download ;;
		W) run_write_iso ;;
		"help"		  ) show_help ;;
		"description" ) show_description ;;
		"readme" 	  ) show_readme ;;
		"bash_history") show_bash_history ;;
		"reboot"	  ) run_reboot ;;
		"quit"		  ) exit 0 ;;
	esac
	main_menu
}

save_log() {
	local logname=$1 logcontent=$2
	local logdir="$INST_DIR/log"
	
	[ "$EMC_installed" = "true" ] && logdir="$HOME/.config/polybar/log"	
	
	local filename="emc_base_installer_${logname}.log.txt"
	local logfile="$logdir/$filename"

	mkdir -p "$logdir"
	printf "%b\n" "$logcontent" > "$logfile" 2>/dev/null
}

can_install() {

	local errcode=$EMC_ok

	check_inet
	if [ "$EMC_running" = "true" ]; then
		msg_box "" "$MSG_EMC_RUNNING"
		errcode=$EMC_runerr
	elif [ "$INET_CONNECTED" = "false" ]; then
		msg_box "" "$MSG_NOT_CONNECTED"
		errcode=$EMC_runerr
	elif [ "$DOWNLOAD_SUCCESS" = "false" ]; then
		msg_box "" "$MSG_NO_DOWNLOAD"
		errcode=$EMC_runerr
	elif [ -z "$EMC_passwd" ]; then
		! get_passwd && errcode=$EMC_pwerr
	fi

	return $errcode
}

run_standalone_install_simulation() {

	local errcode
	
	can_install
	errcode=$?

	if [ $errcode -ne $EMC_ok ]; then
		on_error $errcode
		return
	fi
	do_simulate_install
}

run_standalone_installation() {

	local errcode

	can_install
	errcode=$?

	if [ $errcode -ne $EMC_ok ]; then
		on_error $errcode
		return
	fi
	sudo -E -S <<< "$EMC_passwd" dmesg -n 1
	do_install
}
