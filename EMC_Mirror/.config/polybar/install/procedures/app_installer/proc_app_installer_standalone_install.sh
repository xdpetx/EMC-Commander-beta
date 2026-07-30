#!/bin/bash

# install procedures for EMC_standalone_app_installer:
#
#	is_installable, install_pkg, run_installation
#	remove_pkg, run_remove
#
# DEBIAN VERSION

needs_debconf() {
	local pkg="$1"
	# Prüfe, ob 'debconf' in den Abhängigkeiten auftaucht
	if apt-cache depends "$pkg" | grep -q "debconf"; then
		return 0 # needs debconf
	fi
	return 1 # no debconf
}

is_installable() {
	local pkg="$1"
	local candidate
	
	# Get the candidate version and suppress error messages
	candidate=$(LC_ALL=C apt-cache policy "$pkg" 2>/dev/null | grep "Candidate:" | awk '{print $2}')
	
	# Check if the candidate is empty or (none)
	[[ -z "$candidate" || "$candidate" == "(none)" ]] && return 1 # Not installable
	
	if needs_debconf "$pkg" ;then
		dlg_msg_box "" "Package <span foreground='#FF0000'>$pkg</span> requires interactive configuration (debconf). Install manually!"
		return 1 # Not installable
	fi

	return 0 # Installable
}

is_dirty() {
	local tmp_log="$1" pkg="$2"
	local logfilter="$(mktemp)"
	local warning="⚠️ EMC System warning - additional system Components for package"
	local dirt=""

	filter_dirty > "$logfilter"

	dirt="$(grep -f "$logfilter" "$tmp_log")"

	rm -f "$logfilter"

	if [ -n "$dirt" ]; then
		printf "\n$warning $pkg: \n\n%s\n\n" "$dirt"
		# matches found
		return 0
	fi

	# no matches found
	return 1
}

show_dirty() {

	local tmp_log="$1"
	local pkg="$2"
	local dirt="" exitcode
	local show_dlg="show_is_dirty_dlg = yes"
	local hide_dlg="show_is_dirty_dlg = no"

	dirt="$(is_dirty "$tmp_log" "$pkg")"
	exitcode=$?

	if grep "$hide_dlg" "$_USERDIR/applications.ini"; then
		true
	elif [ $exitcode -eq $yad_ok ]; then
		echo "$dirt$dirty_info" | dlg_is_dirty "$pkg"
		exitcode=$?
		[ $exitcode -eq $yad_cancel ] && sed -i "s/$show_dlg/$hide_dlg/" "$_USERDIR/applications.ini"
	fi
	echo "$dirt"

}

install_pkg() {

	local pkg="$1" install_now="false" apt_install_log install_flags="" 
	local exit_full_sim=0 exit_core_sim=0 exit_compare=0 now
	local core_log tmp_log

	if ! is_installable "$pkg"; then
		now=$(date -R)
		INSTALLATION_RESULT+="### running apt install with $pkg $now ###\n\n"
		INSTALLATION_RESULT+="skip package $pkg: no installation candidate found\n"
		INSTALLATION_RESULT+="\n### package * $pkg * installation done $now ###\n\n\n"
		return
	fi

	tmp_log=$(mktemp)
	core_log=$(mktemp)

	now=$(date -R)
	echo -e "### running FULL install simulation for * $pkg * with sudo apt install $now ###" > "$tmp_log"

	# exec simulated full installation.
	echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt install $pkg 2>&1 >> "$tmp_log" 
	show_dirty "$tmp_log" "$pkg" >> "$tmp_log"
	cat "$tmp_log" | dlg_isim_full "$pkg"
	exit_full_sim=$?

	# Simulate core installation if wanted
	if [ $exit_full_sim -eq $yad_core_sim ]; then

		now=$(date -R)
		echo -e "\n### running CORE install simulation for * $pkg * with sudo apt install --no-install-recommends $now ###" >> "$tmp_log"

		# exec simulated core installation
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt install --no-install-recommends $pkg 2>&1 > "$core_log"
		show_dirty "$core_log" "$pkg" >> "$core_log"
		cat "$core_log" >> "$tmp_log" 
		cat "$core_log" | dlg_isim_core "$pkg"
		exit_core_sim=$?

	# or select full install
	elif [ $exit_full_sim -eq $yad_full_install ]; then
		install_flags=""
		install_now="true"
	fi

	# compare result of full and core simulation if wanted
	if [ $exit_core_sim -eq $yad_compare_log ]; then
		apt_install_log=$(grep -v -E "\[sudo\]|WARNING:" "$tmp_log")
		dlg_isim_compare "$apt_install_log" "$pkg"
		exit_compare=$?
	# or select core install
	elif [ $exit_core_sim -eq $yad_core_install ]; then
		install_flags="--no-install-recommends"
		install_now="true"
	fi

	# select full install after compare
	if [ $exit_compare -eq $yad_full_install ]; then
		install_flags=""
		install_now="true"
	# select core install after compare
	elif [ $exit_compare -eq $yad_core_install ]; then
		install_flags="--no-install-recommends"
		install_now="true"
	fi

	now=$(date -R)
#	INSTALLATION_RESULT+="### running apt install with $pkg $now ###\n\n"

	apt_install_log=$(grep -v -E "\[sudo\]|WARNING:" "$tmp_log")
	#apt_install_log=$(< $tmp_log)
	#apt_install_log=$(cat "$tmp_log")
	rm "$tmp_log" "$core_log"
	now=$(date -R)
	INSTALLATION_RESULT+="$apt_install_log\n"

	if [ "$install_now" = "false" ]; then
		INSTALLATION_RESULT+="\nInstallation aborted\n"
		INSTALLATION_RESULT+="\n### package * $pkg * installation done $now ###\n\n\n"
		return
	fi

	{ 
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt install -y $install_flags $pkg 2>&1
		echo -e "\ndone" 
	} | dlg_show_progress "INSTALLATION PROGRESS" "Installing package: $pkg..."

	now=$(date -R)
	INSTALLATION_RESULT+="\nRESTART INSTALLATION: sudo apt install -y $install_flags $pkg ...\n"	
	INSTALLATION_RESULT+="\n### package * $pkg * installation done $now ###\n\n\n"
}

run_installation() {

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot run installation while another task is running " && return

	touch "$APPINSTALLER_LOCK"
	trap 'rm -f "$APPINSTALLER_LOCK"' RETURN EXIT SIGINT SIGTERM

	INSTALLATION_RESULT=""

	local sel pkg install_state ifs_save pkg_empty=""
	
	ifs_save="$IFS"

 	while IFS='|' read -r sel pkg _ _ install_state _; do
		[ "$pkg" == "(null)" ] && continue
		if [ "$install_state" = "INSTALLED" ]; then
			pkg_empty="false"
			continue
		fi

		if [ "$sel" = "TRUE" ]; then

			[ -z "$EMC_passwd" ] && get_passwd "Installation"
			if [ -z "$EMC_passwd" ]; then
				restore_selection
				return
			fi

			pkg_empty="false"
			install_pkg "$pkg"
		fi
	done <<< "$DLG_SELECTION"

	IFS="$ifs_save"

	if [ -z "$pkg_empty" ]; then
		dlg_msg_box "" "No package selected.\n\n Use [ Search ] button to install not listed packages"
		restore_selection
		return
	fi

	show_log "install" "$INSTALLATION_RESULT"
	get_install_state
	[ ! "$_EMC_FM" = "pcmanfm" ] && $_SCRIPTDIR/setup_fm_applications.sh
}

remove_pkg() {

	local pkg="$1" remove_now="false" remove_cmd="" 
	local yad_exitcode remove_log now

	now=$(date -R)
	tmp_log=$(mktemp)
	trap 'rm -f "$tmp_log"' RETURN

	INSTALLATION_RESULT+="### running sudo apt purge --autoremove  with $pkg ###\n\n"
	{	
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt purge --autoremove $pkg 2>&1 | tee "$tmp_log"
		echo -e "\npress [CANCEL] or [REMOVE NOW] to continue" 
	} | dlg_rsim "$pkg"

	yad_exitcode=$?
	[ $yad_exitcode = $yad_remove ] && remove_now="true"	

	remove_log=$(cat "$tmp_log")

	INSTALLATION_RESULT+="$remove_log\n"

	if [ "$remove_now" = "false" ]; then
		INSTALLATION_RESULT+="\nRemove aborted\n"
		INSTALLATION_RESULT+="\n### package * $pkg * $remove_cmd done ###\n\n\n"
		return
	fi

	{ 
		echo "$EMC_passwd" | LC_ALL=C sudo -S stdbuf -oL apt purge --autoremove -y $pkg 2>&1
		echo -e "\ndone" 
	} | dlg_remove_progress "$pkg"

	INSTALLATION_RESULT+="\nRESTART REMOVE: sudo apt purge --autoremove -y $pkg ...\n"	
	INSTALLATION_RESULT+="\n### package * $pkg * remove done ###\n\n\n"
}

run_remove() { 

	[ -f "$APPINSTALLER_LOCK" ] && notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "cannot run remove while another task is running " && return

	touch "$APPINSTALLER_LOCK"
	trap 'rm -f "$APPINSTALLER_LOCK"' RETURN EXIT SIGINT SIGTERM

	if [ -z "$DLG_SELECTION" ]; then
		dlg_msg_box "" "No package selected.\n\n Use [ Search ] button to remove not listed packages"
		restore_selection
		return
	fi

	[ -z "$EMC_passwd" ] && get_passwd "Remove"
	if [ -z "$EMC_passwd" ]; then
		restore_selection
		return
	fi

	INSTALLATION_RESULT=""

	local sel pkg install_state ifs_save pkg_empty=""

	ifs_save="$IFS"

	while IFS='|' read -r sel pkg _ _ install_state _; do
		[[ "$install_state" != "INSTALLED" ]] && continue

		if [ "$sel" = "TRUE" ]; then
			remove_pkg "$pkg"
			pkg_empty="false"
		fi
	done <<< "$DLG_SELECTION"

	IFS="$ifs_save"

	if [ -z "$pkg_empty" ]; then
		dlg_msg_box "" "Nothing to remove:\n\n selected packages not installed."
		restore_selection
	else
		show_log "Remove" "$INSTALLATION_RESULT"
		get_install_state
		[ ! "$_EMC_FM" = "pcmanfm" ] && $_SCRIPTDIR/setup_fm_applications.sh
	fi
}

