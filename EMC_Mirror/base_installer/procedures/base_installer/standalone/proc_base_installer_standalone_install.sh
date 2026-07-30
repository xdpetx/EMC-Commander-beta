#!/bin/bash

# EMC_standalone_base_installer - install procedures:
#
#	install_standalone_fonts, install_standalone_icons, install_config
#
#	do_install, do_simulate_install, setup_install_log
#
# DEBIAN VERSION

install_standalone_fonts() {
	echo -ne "\r\033[Krunning install_fonts ..." >&2
	echo -e "install_fonts:\n"

	local font_archive="$HOME/.config/polybar/install/emc/EMC_FONTS.tar.gz"
	local tmp_dir="/tmp"
	local font_dir="/usr/share/fonts/truetype/EMC"
	local font

	if [ "$SIMULATION" = "true" ]; then
		echo "   will run mkdir -p $font_dir"
		echo -e "   will run cp ${FONTS[*]} to $font_dir\n"
		return
	fi

	# Create font directory
	LC_ALL=C sudo -E -S <<< "$EMC_passwd" mkdir -p "$font_dir"
	# Extract to font_dir
	LC_ALL=C sudo -E -S <<< "$EMC_passwd" tar -xzf "$font_archive" -C "$font_dir"

	echo -e "\n   FONTS to install: ${FONTS[*]}\n"

	# Update the system font cache to register new fonts
	LC_ALL=C sudo -E -S <<< "$EMC_passwd" fc-cache -f
	echo -e "   Fonts installed and cache updated.\n"

	echo -e "\n   install fonts done\n"
}

# purge unwanted icons
purge_icon_thems() {
	# Purge icon themes and legacy packages that are not needed
	# nuovext2, adwaita and others are strictly blocked here
	echo -e "	Purging legacy themes and bloat ...\n"
	
	sudo -S <<< "$EMC_passwd" apt-get purge -y \
		nuovext2-icon-theme \
		adwaita-icon-theme \
		hicolor-icon-theme \
		lxde-icon-theme \
		gnome-icon-theme

}

install_standalone_icons() {

	echo -ne "\r\033[Krunning install_icons ..." >&2
	echo -e "install_icons:\n"

	local icon_archive="$HOME/.config/polybar/install/emc/EMC_hicolor_icons.tar.gz"
	local icon_dir="/usr/share/icons"

	if [ "$SIMULATION" = "true" ]; then
		echo "   will run mkdir -p $icon_dir"
		echo -e "   will extract EMC_hicolor_icons.tar.gz to $icon_dir\n"
		return
	fi

	# purge unwanted icons
	# purge_icon_thems

	# Create icon directory
	LC_ALL=C sudo -E -S <<< "$EMC_passwd" mkdir -p "$icon_dir"
	if [ -f "$icon_archive" ]; then
		LC_ALL=C sudo -E -S <<< "$EMC_passwd" tar -xzf "$icon_archive" -C "$icon_dir"

		echo -e "\n   Updating hicolor icon cache..."
		LC_ALL=C sudo -E -S <<< "$EMC_passwd" gtk-update-icon-cache "$icon_dir/hicolor" 2>&1

		mkdir -p "$HOME/.config/gtk-3.0"
		printf "%s" "$(gtk_settings)" > "$HOME/.config/gtk-3.0/settings.ini"

		echo -e "\n   install icons done\n"
	else
		echo -e "\n   error: $icon_archive not found!\n"
	fi
}

install_config() {

	local exitcode=0
	
	echo -ne "\r\033[Krunning install_config ..." >&2
	echo -e "install_config:\n"

	# Define local variables for installation and source paths
	local install_dir source_archive
	install_dir="$(dirname "$0")"

	source_archive=$(ls "$install_dir"/EMC_CONFIG.tar.gz 2>/dev/null | head -n 1)

	if [ "$SIMULATION" = "true" ]; then
		echo -e "   EMC config will be extracted to $HOME/.config/\n"
		return
	fi

	# Proceed with real installation if source archive exists
	if [ -f "$source_archive" ]; then
		echo "   Extracting EMC Configuration from $source_archive to $HOME/.config/...\n"

		mkdir -p "$HOME/.config"

		# Extract the archive into the $HOME directory
		# tar -C ensures the files are placed in the correct subdirectories
		tar -xzvf "$source_archive" -C "$HOME"
		exitcode=$?

		if [ $exitcode -eq 0 ]; then
			echo -e "\n   Configuration files successfully extracted."
		else
			echo "\n   Error during extraction of configuration files.\n"
			return $exitcode
		fi
	else
		echo "   Error: Source archive not found in $install_dir"
		return $exitcode
	fi

	echo -e "\n   install config done\n"
}

do_install() {

	SIMULATION="false"

	local terminal="$TERM"
	local now=$(date -R) line=""
	local info_txt="$(get_standalone_package_info)"
	local install_log="" logcontent="" simulation_txt=""
	local syslog_minimal syslog_emc_base
	local header="$(mktemp)"

	syslog_minimal="$(system_report)"

	> "$TMP_LOG"

	echo "### EMC INSTALLATION BEGIN $now ###" > "$header" 
	sys_header >> "$header" 

	TERM=ansi

	if ! full_confirmation_box "INSTALL info" "$INST_NOTE$info_txt"; then
		TERM="$terminal"
		clear
		return 1
	fi

	echo -e "Install packages :\n\n   see installation log after INSTALLATION END\n" >> "$header" 

	install_standalone_packages "${INSTALL_PACKAGES[@]}"

	install_config >> "$header" 
	install_standalone_fonts >> "$header" 
	install_standalone_icons >> "$header" 
	setup_desktop >> "$header" 
	setup_keyboard >>"$header"  
	finish_setup >> "$header" 

	TERM="$terminal"
	clear

# DEBUG
#logcontent="$(cat "$TMP_LOG")"
#save_log "install_raw_output" "$logcontent"

	INSTALL_SUCCESS="true"
	check_system
	syslog_emc_base="$(system_report)"

	now=$(date -R)
	echo -e "### EMC INSTALLATION END   $now ###\n" >> "$header" 
	echo -e "\n########## INSTALLATION LOG ##########\n" >> "$header" 

	# obsolete now ? 
	setup_install_log "$header" "$TMP_LOG"

	show_log "install" "$TMP_LOG"
	logcontent="\n$(cat "$TMP_LOG")"

	save_log "install" "$logcontent"
	save_log "syscheck_minimal_system" "$syslog_minimal"
	save_log "syscheck_emc_base" "$syslog_emc_base"
}

do_simulate_install() {

	SIMULATION="true"

	local terminal="$TERM"
	local now=$(date -R)
	local info_txt="$(get_standalone_package_info)"

	TERM=ansi

	if ! full_confirmation_box "INSTALL Simulation" "$ISIM_NOTE$info_txt"; then
		TERM="$terminal"
		clear
		return 1
	fi

	local header="$(mktemp)" tmp01="$(mktemp)" logcontent="" 

	> "$TMP_LOG"

	echo -e "### EMC INSTALL SIMULATION BEGIN $now ###" > "$header" 
	sys_header >> "$header"  

	install_config >> "$header" 
	install_standalone_fonts >> "$header" 
	install_standalone_icons >> "$header" 
	setup_desktop >> "$header" 
	setup_keyboard >>"$header"  
	finish_setup >> "$header" 

	echo -e "### TOTAL INSTALLATION SIZE estimated ###\n" >> "$TMP_LOG"
	LC_ALL=C apt-get install -y "${INSTALL_PACKAGES[@]}" --print-uris | grep -E "After this operation" >> "$TMP_LOG"

	TERM="$terminal"
	clear

	cat "$header"  "$TMP_LOG"> "$tmp01"
	cat "$tmp01" > "$TMP_LOG"


	show_log "simulate_install" "$TMP_LOG"
	logcontent="\n$(cat "$TMP_LOG")"

	save_log "install_sim" "$logcontent"

	rm -f "$tmp01" "$header"
}

# obsolete now ? 
setup_install_log() {
	local tmp01="$(mktemp)"
	local filter="$(mktemp)"
	local summary="$(mktemp)"
	local header="$1"
	local logfile="$2"
	local mode=${3:-INSTALLATION}

	# 1. Get filter patterns
	apt_install_filter > "$filter"

	# 2. Filtering logfile
	grep -F -v -f "$filter" "$logfile" > "$tmp01"

	# 3. Clean up the APT noise (Reading package lists... until NEW packages)
	# We use a temporary file to ensure we don't truncate the log on error
	local begin="Reading package lists..."
	local end="The following NEW packages will be installed:"
	sed "/$begin/,/$end/{/$end/!d}" "$tmp01" > "$logfile"

	# 4. Remove excessive empty lines (squeeze)
	sed -i '/^$/N;/\n$/D' "$logfile"

	# 5. Clean up the APT noise (The following NEW packages... until newly installed,)
	# We use a temporary file to ensure we don't truncate the log on error
	begin="The following NEW packages will be installed:"
	end="newly installed,"
	sed "/$begin/,/$end/{/$end/!d}" "$logfile" > "$tmp01"

	# 6. Get filter patterns
	apt_install_summary_filter > "$filter"

	# 7. Filtering summary
	grep -F -v -f "$filter" "$tmp01" > "$summary"

	printf "\n########## $mode LOG OVERVIEW ##########\n" >> "$header"
	printf "\n########## $mode LOG DETAILS  ##########\n\n" >> "$summary"

	cat "$header" "$summary" "$logfile"> "$tmp01"
	cat "$tmp01" > "$logfile"

	# Cleanup
	rm -f "$tmp01" "$filter" "$summary" "$header"

}
