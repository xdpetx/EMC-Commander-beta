#!/bin/bash

# EMC_standalone_base_installer:
#	This script installs EMC Base packages for standalone system:
#
#	packages for extended apt support
#	packages for x11
#	packages for bluetooth support
#	packages for printer support
#
#	packages for EMC like Polybar and i3
#	package  for selected filemanager
#
#	some fonts and icons
#
# DEBIAN VERSION

# packages for extended apt support
APT_BASE=(apt-rdepends apt-file apt-show-versions debsecan)

# packages for x11
X11_BASE=(xserver-xorg-core xserver-xorg xinit x11-xserver-utils)

# packages for bluetooth support
BLUETOOTH_BASE=(bluez pulseaudio-module-bluetooth)

# packages for printer support
PRINTER_BASE=(cups cups-client cups-filters avahi-daemon printer-driver-all foomatic-db-compressed-ppds)

# basic system packages
SYSTEM_BASE=(desktop-file-utils xsel psmisc shared-mime-info fontconfig polkitd lxpolkit pkexec plocate network-manager alsa-utils pavucontrol)

# EMC packages for EMC
EMC_BASE=(i3-wm polybar dunst jq lshw maim yad fonts-noto-color-emoji libnotify-bin bc inxi)

# filemanager to install
FM_BASE=(pcmanfm)

# package list for complete install
INSTALL_PACKAGES=()
INSTALL_PACKAGES_INSTALL_STATE=()
ALL_PACKAGES=("${APT_BASE[@]}" "${X11_BASE[@]}" "${BLUETOOTH_BASE[@]}" "${PRINTER_BASE[@]}" "${SYSTEM_BASE[@]}" "${EMC_BASE[@]}" "${FM_BASE[@]}")

FONTS=(SymbolsNerdFontMono-Regular.ttf NotoSans-Regular.ttf DejaVuSansMono.ttf)

OS=""
OS_LIKE=""
OS_FAMILY=""
DESKTOP_ENV=""
AVAILABLE_DESKTOP_SESSIONS=""
SYSTEM_LOCALE=""

i3_install_VERSION=""
polybar_install_VERSION=""
i3_avail_VERSION=""
polybar_avail_VERSION=""
polybar_short_VERSION=""
polybar_required_VERSION="3.7.0"
polybar_required_short_VERSION="370"

#status variables
EMC_install_flag="$HOME/.config/polybar/.EMC_install_flag"
EMC_installed="false"
EMC_running="false"
EMC_passwd=""

SIMULATION="true"
MINIMAL_SYSTEM="false"
STANDALONE_SYSTEM="false"
DESKTOP_SYSTEM="false"

#exit codes
readonly EMC_error=113
readonly EMC_runerr=64
readonly EMC_pwerr=65
readonly EMC_pwcancel=66

readonly EMC_ok=0
readonly EMC_no=125

ISO_DOWNLOAD_SUCCESS=""
ISO_DOWNLOAD=""
DOWNLOAD_SUCCESS="false"
INSTALL_SUCCESS="false"
INET_CONNECTED="false"
DOWNLOAD_SIZE=0
DOWNLOAD_SPEED=""
USB_DEV=""

DEBIAN_ISO=""
INST_DIR="$(dirname "$(readlink -f "$0")")"
PROC_DIR="$(dirname "$0")/procedures/base_installer/standalone"
TMP_LOG=$(mktemp /tmp/EMC_logfile.XXXXXX)

DOWNLOAD_DIR="/tmp/EMC_Download"

trap 'rm -f "$TMP_LOG"' EXIT

if ! command -v "whiptail" >/dev/null 2>&1; then
	echo "Need whiptail to run installer. Install with sudo apt install whiptail"
	exit 1
fi

if [ -d "$PROC_DIR" ]; then
	for proc_file in "$PROC_DIR"/proc_base_installer_*.sh; do
		source "$proc_file"
	done
else
	echo "Error: Procedure directory $PROC_DIR not found!"
	exit 1
fi

# run first for initialize variables
check_system

echo "starting EMC_standalone_base_installer ..."

[ "$MINIMAL_SYSTEM" = "true" ] && check_apt_cache

# then load text with these variables
source "$PROC_DIR/txt_base_installer_standalone.sh"

mkdir -p "$DOWNLOAD_DIR"

#read -p "DEBUG press [ENTER]"

main_menu
