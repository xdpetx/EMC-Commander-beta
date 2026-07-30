#!/bin/bash

# EMC_standalone_base_installer - check procedures:
#
#	check_os, check_desktop_env
#	check_version, check_install
#	check_system
#
# DEBIAN VERSION

# check os and set os specific packages
check_os() {

	if [ -f /etc/os-release ]; then
		# get OS-vars
		source /etc/os-release
		#OS=$ID  #e.g. "ubuntu", "debian", "arch"
		OS="$PRETTY_NAME"  #e.g. "ubuntu", "debian", "arch"
		OS_LIKE="$ID_LIKE"
		OS_FAMILY="$ID"
	else
		OS="unknown"
		echo "Error - Unknown OS. Cannot install EMC."
		exit 1 # cannot install dependencies script aborted
	fi
}

check_desktop_env() {
	local session i3_sessions=0 no_i3_sessions=0 

	MINIMAL_SYSTEM="false"
	STANDALONE_SYSTEM="false"
	DESKTOP_SYSTEM="false"

	AVAILABLE_DESKTOP_SESSIONS=""
	# Scan for available desktop sessions
	for session in /usr/share/xsessions/*.desktop /usr/share/wayland-sessions/*.desktop; do
		if [ -e "$session" ]; then
			session="${session##*/}"
			AVAILABLE_DESKTOP_SESSIONS+="$session "
			case "$session" in
				i3.desktop | i3-with-shmlog.desktop | i3_EMC.desktop ) ((i3_sessions++));;
				*) ((no_i3_sessions++));;
			esac
		fi
	done

	# Define system type based on detected sessions
	if [ "$no_i3_sessions" -eq 0 ]; then
		STANDALONE_SYSTEM="true"
		DESKTOP_SYSTEM="false"
	else
		DESKTOP_SYSTEM="true"
		STANDALONE_SYSTEM="false"
	fi

	# Override for empty/minimal systems
	if [ -z "$AVAILABLE_DESKTOP_SESSIONS" ]; then
		# only debian systems can be a valid minimal system
		if [ "$OS_FAMILY" = "debian" ]; then
			if [ "$i3_sessions" -eq 0 ]; then
				MINIMAL_SYSTEM="true"
				STANDALONE_SYSTEM="false"
			else
				MINIMAL_SYSTEM="false"
				STANDALONE_SYSTEM="true"
			fi
		fi
	fi

	DESKTOP_ENV="${DESKTOP_SESSION:-UNKNOWN_DESKTOP}"
	[ "$INSTALL_SUCCESS" = "true" ] && DESKTOP_ENV="i3_EMC"

}

check_version() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return

	i3_avail_VERSION=$(LC_ALL=C apt-cache policy i3 | grep -m 1 "Candidate:" | cut -d: -f2 | xargs)
	polybar_avail_VERSION=$(LC_ALL=C apt-cache policy polybar 2>/dev/null | grep -m 1 "Candidate:" | cut -d: -f2 | xargs || echo "0")
	polybar_short_VERSION=$(echo "$polybar_avail_VERSION" | tr -d '.')
	polybar_short_VERSION="${polybar_short_VERSION:0:3}"

	# obsolete debian 13 has polybar 3.7.2
	if [ $polybar_short_VERSION -lt $polybar_required_short_VERSION ]; then
		echo	"Available polybar version $polybar_avail_VERSION: CANNOT INSTALL EMC"
		echo	"polybar version $polybar_required_VERSION or greater is not available on your system"
		echo -e "Try to install polybar version $polybar_required_VERSION or greater manually\n"
		exit 1
	fi
}

# check installation i3, polybar and PACKAGES
check_install() {

	i3_install_VERSION=$(i3 -v 2>/dev/null | cut -d" " -f1-4)
	polybar_install_VERSION=$(polybar -v 2>/dev/null | head -n 1)

	if [ "$MINIMAL_SYSTEM" = "true" ]; then
		INSTALL_PACKAGES=("${ALL_PACKAGES[@]}")
	elif [ "$INSTALL_SUCCESS" = "true" ]; then
		INSTALL_PACKAGES=("${ALL_PACKAGES[@]}")
	else
		INSTALL_PACKAGES=()
	fi

	INSTALL_PACKAGES_INSTALL_STATE=($(get_packages_install_state "${INSTALL_PACKAGES[@]}"))


	[ -z "$i3_install_VERSION" ] && return
	[ -z "$polybar_install_VERSION" ] && return
	[ -f "$EMC_install_flag" ] && EMC_installed="true"
	if [ ! -z "$(pgrep polybar)" ]; then
		EMC_running="true"
		if [ ! -f "$EMC_install_flag" ]; then
			echo "EMC Install Flag. Do not remove!" > "$EMC_install_flag"
			chmod 444 "$EMC_install_flag"
			EMC_installed="true"
		fi
	fi

}

check_inet() {

	INET_CONNECTED="false"
	
	# ping one of the root name servers
	! ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1 && return
	# verify connectivity
	! getent hosts debian.org > /dev/null 2>&1 && return

	INET_CONNECTED="true"
}

# check users system
check_system() {

	check_os
	check_desktop_env
	check_version
	check_install
	check_inet

	SYSTEM_LOCALE=$(env | grep "^LANG=" | cut -d= -f2)
}
