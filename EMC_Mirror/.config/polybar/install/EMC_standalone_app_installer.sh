#!/bin/bash

# This script installs software for standalone EMC 
# DEBIAN VERSION

# Exit if EMC configuration is missing
if [ ! -d "$HOME/.config/polybar" ]; then
	echo "EMC not installed - install EMC first"
	exit
fi

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=1500
readonly APP_INSTALLER_INSTANCE="EMC_App_Installer"

PIDFILE="/tmp/EMC_appinstaller.pid"
APPINSTALLER_LOCK="/tmp/EMC_appinstaller.lock"
SEARCH_DESCRIPTIONS=$(mktemp /tmp/EMC_search_descriptions_XXXXXX)
TMP_passwd=$(mktemp)

if [ -f "$PIDFILE" ]; then
	i3-msg "[instance=\"$APP_INSTALLER_INSTANCE\"] focus" > /dev/null 2>&1 && exit
fi

# pid of script
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE" "$SEARCH_DESCRIPTIONS" "$TMP_passwd"' EXIT

OS=""
OS_ID=""
OS_LIKE=""
OS_FAMILY=""
DESKTOP_ENV=""
AVAILABLE_DESKTOP_SESSIONS=""
SYSTEM_LOCALE=$(env | grep "^LANG=" | cut -d= -f2)

STANDALONE_SYSTEM="true"

i3_install_VERSION=$(i3 -v 2>/dev/null | cut -d" " -f1-4)
polybar_install_VERSION=$(polybar -v 2>/dev/null | head -n 1)
i3_avail_VERSION=$(LC_ALL=C apt-cache policy i3 | grep -m 1 "Candidate:" | cut -d: -f2 | xargs)
polybar_avail_VERSION=$(LC_ALL=C apt-cache policy polybar 2>/dev/null | grep -m 1 "Candidate:" | cut -d: -f2 | xargs || echo "0")

INSTALLATION_RESULT=""

EMC_passwd=""

PROC_DIR="$(dirname "$0")/procedures/app_installer"
INET_CONNECTED="false"
DOWNLOAD_SPEED=""

# include procedures
if [ -d "$PROC_DIR" ]; then
	for proc_file in "$PROC_DIR"/proc_app_installer_standalone_*.sh; do
		source "$proc_file"
	done
else
	echo "Error: Procedure directory $PROC_DIR not found!"
	exit 1
fi

check_apt_cache "startup"
check_os
check_desktop_env
check_inet

get_install_state

# first close all Info and Help notifies
dunstctl close-all

run_main_dlg
