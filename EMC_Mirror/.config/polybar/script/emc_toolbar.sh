#!/bin/bash

TOOLBAR_TITLE=" EMC Configuration"
TOOLBAR_TXT="dbl click mainbar space toggles hide / show"
TOOLBAR_PID="/tmp/EMC_toolbar.flag"

# colors from polybar config.ini
readonly color_primary=#F0C674
readonly color_secondary=#8ABEFF
readonly color_background=#282A2E
readonly EMC_TOOLBAR_INSTANCE="EMC_Toolbar"

readonly icon_toolbar="<span background='$color_background' foreground='$color_primary'> 󱁤 </span>"

get_toolbar_buttons() {

	local -n toolbar_buttons=$1
	local btn_txt="Mainbar Info"
	local btn_hint="Do not show Mainbar Info on start"
	local show_on_start="show_mainbar_info_on_start = yes"

	toolbar_buttons=(
"--button=Software!emc-software-installer!start App Installer:10"
"--button=Starter!emc-gtk-edit!edit applications.ini:20"
"--button=Tooltips!emc-gtk-edit!edit tooltips.ini:30"
"--button=Icons!emc-gtk-edit!edit icons.ini:40"
"--button=Monitor!emc-gtk-edit!edit monitor.ini:50"
"--button=Workspace!emc-gtk-edit!edit config_workspaces:60"
"--button=Usercmd!emc-gtk-edit!edit config_usercommands:70")

	grep "$show_on_start" "$_USERDIR/applications.ini" && toolbar_buttons+=("--button=$btn_txt!emc-user-trash!$btn_hint:90")

}

show_emc_toolbar() {

local selection=0 yad_buttons=()

get_toolbar_buttons yad_buttons

yad --name="$EMC_TOOLBAR_INSTANCE" \
--title="$TOOLBAR_TITLE" \
--text="$TOOLBAR_TXT" \
--text-align="center" \
--window-icon="emc-gtk-preferences" \
--fixed \
--borders=1 \
"${yad_buttons[@]}" \
--buttons-layout center &

	echo $! > "$TOOLBAR_PID"
	sleep 0.2
	# get focus back
	i3-msg "[instance=\"$EMC_TOOLBAR_INSTANCE\"] focus"
	wait $!

	selection=$?

	touch "$TOOLBAR_PID"
	exec_emc_toolbar $selection

}

hide_emc_toolbar() {
	[ -s "$TOOLBAR_PID" ] && kill "$(cat "$TOOLBAR_PID")" 2>/dev/null
	rm -f "$TOOLBAR_PID";
	exit 0
}

exec_emc_toolbar() {
	local selection=$1

	local show_on_start="show_mainbar_info_on_start = yes"
	local hide_on_start="show_mainbar_info_on_start = no"

	case $selection in
		# use setsid to completely detach the process from the main script.
		# redirecting to /dev/null prevents output from cluttering the window.
		10) setsid --fork $_BASEDIR/install/EMC_standalone_app_installer.sh > /dev/null 2>&1 & ;;
		20) setsid --fork xdg-open $_USERDIR/applications.ini > /dev/null 2>&1 & ;;
		30) setsid --fork xdg-open $_USERDIR/tooltips.ini > /dev/null 2>&1 & ;;
		40) setsid --fork xdg-open $_USERDIR/icons.ini > /dev/null 2>&1 & ;;
		50) setsid --fork xdg-open $_USERDIR/monitor.ini > /dev/null 2>&1 & ;;
		60) setsid --fork xdg-open $_i3_BASEDIR/usr/config_workspaces > /dev/null 2>&1 & ;;
		70) setsid --fork xdg-open $_i3_BASEDIR/usr/config_usercommands > /dev/null 2>&1 & ;;
		90) sed -i "s/$show_on_start/$hide_on_start/" "$_USERDIR/applications.ini";;
		*)  hide_emc_toolbar ;;
	esac

	show_emc_toolbar
}

xexec_emc_toolbar() {

	local selection=$1

	local show_on_start="show_mainbar_info_on_start = yes"
	local hide_on_start="show_mainbar_info_on_start = no"

	case $selection in
		10) $_BASEDIR/install/EMC_standalone_app_installer.sh &;;
		20) xdg-open $_USERDIR/applications.ini &;;
		30)	xdg-open $_USERDIR/tooltips.ini &;;
		40) xdg-open $_USERDIR/icons.ini > /dev/null 2>&1 & ;;
		50) xdg-open $_USERDIR/monitor.ini > /dev/null 2>&1 & ;;
		60) xdg-open $_i3_BASEDIR/usr/config_workspaces > /dev/null 2>&1 & ;;
		70) xdg-open $_i3_BASEDIR/usr/config_usercommands > /dev/null 2>&1 & ;;
		90) sed -i "s/$show_on_start/$hide_on_start/" "$_USERDIR/applications.ini";;
		*)  hide_emc_toolbar ;;
	esac

	show_emc_toolbar
}

[ -s "$TOOLBAR_PID" ] && hide_emc_toolbar

# first close all Info and Help notifies
dunstctl close-all

touch "$TOOLBAR_PID"
show_emc_toolbar

