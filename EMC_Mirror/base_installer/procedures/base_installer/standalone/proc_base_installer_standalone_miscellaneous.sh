#!/bin/bash

# EMC_standalone_base_installer - miscellaneous procedures:
#
#	cleanup, on_error, get_passwd
#	get_standalone_package_info, system_report, check_apt_cache
#
# DEBIAN VERSION

cleanup() {

	[ "$INST_DIR" = "$HOME/.config/polybar/install" ] && return

	[ ! "$INSTALL_SUCCESS" = "true" ] && return

	local source="EMC_INSTALL_standalone.tar.gz"
	local dest="EMC_INSTALL_standalone_$(date +%Y_%m_%d).tar.gz"

	echo -e "   running cleanup ...\n"

	cp "$INST_DIR/log/"* "$HOME/.config/polybar/log/" 2>/dev/null
	sync
	cd "$HOME"
	mv "$HOME/Downloads/$source" "$HOME/EMC_Backup/$dest"
	rm -rf "$INST_DIR"
	rm -rf "$DOWNLOAD_DIR"
	rm -rf "$HOME/.config/polybar/install/emc"
}

on_error() {

	local err_code=$1
	
	case "$err_code" in
		$EMC_ok)		: ;;
		$EMC_error)		: ;;
		$EMC_runerr)	: ;;
		$EMC_pwerr)		: ;;
		$EMC_pwcancel)	: ;;
	esac

}

kernel_be_quiet() {
	# Cache the password once for the session.
	echo "$EMC_passwd" | sudo -S -v

	# Permanent settings (via file)
	echo "kernel.printk = 3 4 1 3" | sudo tee /etc/sysctl.d/99-quiet-kernel.conf > /dev/null
}

get_passwd() {
	local trial exit_code back_title=""
	sudo -k

	for trial in 1 2 3; do
		# request password

		EMC_passwd=$(input_box "Password required ($trial. trial from 3)" "\nEnter your password" 11 65)
		exit_code=$?

		# cancelled by user
		if [ $exit_code -ne 0 ]; then
			echo "password request cancelled by user. exit code: $exit_code"
			return $EMC_pwcancel
		fi

		# is empty?
		if [ -z "$EMC_passwd" ]; then
			DLG_BACKTITLE="### EMPTY PASSWORD, try again ###"
			back_title="$DLG_BACKTITLE"
			continue
		fi

		# fast passwd check
		#if timeout 0.2s sudo -S <<< "$EMC_passwd" true 2>/dev/null; then
		if echo "$EMC_passwd" | sudo -S -v >/dev/null 2>&1; then
			return 0
		else
			DLG_BACKTITLE="### WRONG PASSWORD: $EMC_passwd, try again ###"
			back_title="$DLG_BACKTITLE"
		fi
		
		EMC_passwd=""
	done

	# errmsg after 3 invalid passwd
	back_title="${back_title%%,*}, no more trials left ###"
	DLG_BACKTITLE="$back_title"
	msg_box "Password Error" "3 incorrect password attempts, return to caller"

	echo "3 incorrect password attempts, aborted"
	return $EMC_pwerr
}

get_standalone_package_info() {
	local i pkg ist count=0 num_pkg="${#INSTALL_PACKAGES[@]}" counter
	# Header
	local package_info="$(printf "   %5s %-13s     %-28s" "COUNT" "STATE" "PACKAGE")\n\n"

	for i in "${!INSTALL_PACKAGES[@]}"; do
		((count++))
		 if [ "$count" -lt 10 ]; then
			counter="0$count/$num_pkg"
		else
			counter="$count/$num_pkg"
		fi
		pkg="${INSTALL_PACKAGES[$i]}"
		ist="${INSTALL_PACKAGES_INSTALL_STATE[$i]}"

		case "$pkg" in
			"apt-rdepends")
				package_info+="$(printf "   %5s %-13s     %-28s   extended apt support" "$counter" "$ist" "$pkg")\n" ;;
			"xserver-xorg-core")
				package_info+="$(printf "\n   %5s %-13s     %-28s   x11 packages" "$counter" "$ist" "$pkg")\n" ;;
			"bluez")
				package_info+="$(printf "\n   %5s %-13s     %-28s   packages for bluetooth support" "$counter" "$ist" "$pkg")\n" ;;
			"cups")
				package_info+="$(printf "\n   %5s %-13s     %-28s   packages for printer support" "$counter" "$ist" "$pkg")\n" ;;
			"desktop-file-utils")
				package_info+="$(printf "\n   %5s %-13s     %-28s   system base packages" "$counter" "$ist" "$pkg")\n" ;;
			"i3-wm")
				package_info+="$(printf "\n   %5s %-13s     %-28s   EMC base packages" "$counter" "$ist" "$pkg")\n" ;;
			"pcmanfm"|"spacefm"|"konqueror"|"dolphin")
				package_info+="$(printf "\n   %5s %-13s     %-28s   EMC filemanager" "$counter" "$ist" "$pkg")\n" ;;
			*)
				package_info+="$(printf "   %5s %-13s     %-28s" "$counter" "$ist" "$pkg")\n" ;;
			esac
	done
	
	echo -e "$package_info"
}

system_report() {
	local os_release disk_space pkg_installed gtk_lib qt_lib kde_lib
	local mem_free proc_state apt_cache_time syslog="" full_sys_report=""
	local now=$(date -R)

	os_release=$(cat /etc/os-release)
	disk_space=$(LC_ALL=C df -h / "$HOME" "$(dirname "$0")")
	mem_free=$(LC_ALL=C free -hltw)
	proc_state=$(LC_ALL=C ps -eo pcpu,pmem,comm --sort=-pcpu | head -n 11)

	check_inet

	syslog+="### SYSTEM REPORT $now ###\n\n"
	syslog+="1. SYSTEM\n\n"

	syslog+="   Internet connected: $INET_CONNECTED\n"
	if [ -z "$DOWNLOAD_SPEED" ]; then
		syslog+="\n"
	else
		syslog+="   Download speed    : $DOWNLOAD_SPEED MB/s\n\n"
	fi
	syslog+="   OS                : $OS ($OS_FAMILY)\n"
	syslog+="   Desktop           : $DESKTOP_ENV\n"
	syslog+="   Desktop sessions  : $AVAILABLE_DESKTOP_SESSIONS\n"
	if [ "$EMC_running" = "true" ]; then
		syslog+="   Standalone EMC    : $STANDALONE_SYSTEM\n"
		syslog+="   Desktop    EMC    : $DESKTOP_SYSTEM\n"
	fi
	syslog+="   Minimal system    : $MINIMAL_SYSTEM\n\n"

	syslog+="   System Locale     : $SYSTEM_LOCALE\n\n"

	[ -z "$i3_install_VERSION" ] && syslog+="   Available version i3     : $i3_avail_VERSION\n"
	[ ! -z "$i3_install_VERSION" ] && syslog+="   i3      found - $i3_install_VERSION\n"

	[ -z "$polybar_install_VERSION" ] && syslog+="   Available version polybar: $polybar_avail_VERSION\n"
	[ ! -z "$polybar_install_VERSION" ] && syslog+="   polybar found - $polybar_install_VERSION\n\n"

	[ "$EMC_installed" = "true" ] && syslog+="   EMC already installed\n"
	[ "$EMC_running" = "true" ] && syslog+="   EMC is running now\n"

	[ "$MINIMAL_SYSTEM" = "true" ] && full_sys_report="true"
	[ "$EMC_running" = "true" ] && full_sys_report="true"
	[ "$INSTALL_SUCCESS" = "true" ] && full_sys_report="true"
	if [ -z "$full_sys_report" ]; then
		echo -e "$syslog"
		return
	fi

	apt_cache_time=$( { TIMEFORMAT="real: %R\nuser: %U\nsys : %S"; time apt-cache show bash > /dev/null; } 2>&1 )
	pkg_installed=$(LC_ALL=C dpkg -l | grep '^ii' | wc -l)
	gtk_lib=$(dpkg -l | grep "libgtk")
	qt_lib=$(dpkg -l | grep "libqt")
	kde_lib=$(dpkg -l | grep "libkde")

	syslog+="\n2. DISK SPACE\n"	
	syslog+="\n$disk_space\n"
	syslog+="\n3. INSTALLED PACKAGES: $pkg_installed\n"
	syslog+="\n4. MEMORY USAGE\n"	
	syslog+="\n$mem_free\n"
	syslog+="\n5. ACTIVE PROCESSES \n"	
	syslog+="\n$proc_state\n"
	syslog+="\n6. APT CACHE TIME \n"	
	syslog+="\n$apt_cache_time\n"

	syslog+="\n7. GUI LIBRARIES (BLOAT CHECK)\n"
	syslog+="\nGTK:\n\n${gtk_lib:-none}\n"
	syslog+="\nQT:\n\n${qt_lib:-none}\n"
	syslog+="\nKDE:\n\n${kde_lib:-none}\n"

	echo -e "$syslog"
}

check_apt_cache() {

	echo "checking apt cache, this may take a while ..."

	# We measure the time for a standard query
	local start_ms end_ms duration
	# Get start time in milliseconds
	start_ms=$(date +%s%3N)
	# Perform a silent test query
	apt-cache show bash > /dev/null 2>&1
	# Get end time
	end_ms=$(date +%s%3N)
	duration=$((end_ms - start_ms))

	# Threshold: 500ms is already slow, 1000ms is critical
	if [ "$duration" -gt 250 ]; then
		local apt_cache_time=$( { TIMEFORMAT="real: %R\nuser: %U\nsys : %S"; time apt-cache show bash > /dev/null; } 2>&1 )

		yesno_box " Check apt cache " "Cannot run installer with bad apt cache:\n\n$apt_cache_time\n\nDo you want to repair apt cache now?"
		if [ $? -eq 0 ]; then
			get_passwd
			[ -z "$EMC_passwd" ] && exit 2

			local terminal="$TERM" fail_state=0

			TERM=ansi

			info_box "Check apt cache" "repair apt cache\n\n$apt_cache_time" 12

			echo -ne "\r\033[K clear cache" >&2
			sudo -S <<< "$EMC_passwd" rm -f /var/cache/apt/*.bin || fail_state=1
			echo -ne "\r\033[K check apt database" >&2
			sudo -S <<< "$EMC_passwd" apt-get check > /dev/null 2>&1 || fail_state=2
			set -o pipefail
			sudo -S <<< "$EMC_passwd" stdbuf -oL apt update 2>&1 | while read -r line; do
				echo -ne "\r\033[K run apt update: $line" >&2
			done || fail_state=3
			set +o pipefail

			TERM="$terminal"
			clear

			if [ "$fail_state" = "0" ]; then
				apt_cache_time=$( { TIMEFORMAT="real: %R\nuser: %U\nsys : %S"; time apt-cache show bash > /dev/null; } 2>&1 )
				msg_box "Check apt cache success" "Cache rebuilt successfully:\n\n$apt_cache_time\n" 14 60
			else
				msg_box "Check apt cache Error" "Repair failed! Check internet or sudo permissions. Exit now" 9 60
				exit 1
			fi
		else
			echo "cash repair cancelled."
			exit 2
		fi
	fi
}
