#!/usr/bin/env bash

# --- Environment Setup ---
export _BASEDIR="$HOME/.config/polybar"
export _i3_BASEDIR="$HOME/.config/i3"
export _SCRIPTDIR="$_BASEDIR/script"
#export _SCRIPTDIR_i3="$_BASEDIR/i3/script"
#export _SCRIPTDIR_USR="$_BASEDIR/usr/script"
export _BINARIES="$_BASEDIR/bin"
export _i3_SCRIPTDIR="$_BASEDIR/i3/script"
export _USERDIR="$_BASEDIR/usr"
export _ICONDIR="/usr/share/icons/EMC"
export _USERSCRIPT="$_BASEDIR/usr/script"
export _POLYBARVERSION
export _PBAR_VERSION
export _EMC_FM

LOG_FILE="/tmp/EMC_launch.log"

# get os info
OS_RELEASE=$(cat /etc/os-release)

# get polybar version
_POLYBARVERSION=$(polybar -v | head -n 1 | cut -d ' ' -f 2)
_PBAR_VERSION=$(echo "$_POLYBARVERSION" | tr -d '.')
_PBAR_VERSION="${_PBAR_VERSION:0:3}"

i3_VERSION=$(i3 -v | cut -d" " -f 1-4)

# set polybar config
if [ "$_PBAR_VERSION" -lt 370 ]; then
	echo "polybar 3.7.0 required. cannot run EMC."
	exit
else
	PBAR_CONFIG="$_BASEDIR/config.ini"
fi

# get users ws icons in icons.ini
"$_SCRIPTDIR/get_ws_icons.sh"
#load monitor config for actual resolution
"$_SCRIPTDIR/change_resolution.sh"

# reset pid Flags and other lock files
rm -f /tmp/polybar_*
rm -f /tmp/EMC*

# use the nuclear option:
killall -q polybar

# additional info for log file
INFO+="--- EMC launch at $(date -R) ---\n\n"
INFO+="OS - Release:\n\n"
INFO+="$OS_RELEASE\n\n"
INFO+="$i3_VERSION\n\n"
INFO+="Polybar Version: $_POLYBARVERSION\n"
INFO+="short   Version: $_PBAR_VERSION\n"
INFO+="Polybar config : $PBAR_CONFIG\n"
#INFO+="xxx\n"

echo -e "$INFO" > "$LOG_FILE"

if [ -f "$_BASEDIR/xrandr_fail" ]; then
	"$_SCRIPTDIR/set_resolution.sh &"
	rm "$_BASEDIR/xrandr_fail"
fi

# is install flag corrupted?
emc_install_flag="$_BASEDIR/.EMC_install_flag"
if [ ! -f "$emc_install_flag" ]; then
	echo "EMC Install Flag. Do not remove!" > "$emc_install_flag"
	chmod 444 "$emc_install_flag"
fi

PBAR_CONFIG="$_BASEDIR/config.ini"

_EMC_FM=$(grep "^EMC_FM" "$PBAR_CONFIG" | cut -d'=' -f2 | tr -d '[:space:]')
echo -e "EMC filemanager: $_EMC_FM\n" >> "$LOG_FILE"

# copy config for spacefm
if [ "$_EMC_FM" = "spacefm" ]; then
#	rm -rf "$HOME/.config/spacefm"
#	mkdir -p "$HOME/.config/spacefm"
#	cp "$_BASEDIR/install/emc/session_spacefm_EMC" "$HOME/.config/spacefm/session"
	true
fi

# Launch mainbar
case $1 in
     "i3") polybar -c "$PBAR_CONFIG" main_i3 2>&1 | tee -a "$LOG_FILE" & disown;;
        *) polybar -c "$PBAR_CONFIG" main_i3 2>&1 | tee -a "$LOG_FILE" & disown;;
esac

"$_i3_SCRIPTDIR/i3_open_ws.sh" 1 s_ws1

SHOW_MAINBAR_INFO=$(grep show_mainbar_info_on_start $HOME/.config/polybar/usr/applications.ini | cut -d "=" -f 2 | tr -d "[:space:]\"'")

case "$SHOW_MAINBAR_INFO" in
	"yes" | "YES") $HOME/.config/polybar/i3/script/i3_info_mainbar.sh left;;
esac

echo "Bars launched..."
