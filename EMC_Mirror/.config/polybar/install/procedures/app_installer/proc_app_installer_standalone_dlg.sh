#!/bin/bash

# Dialogs, buttons and exitcodes for EMC_standalone_app_installer:
#
#	BTN_INSTALL_PKG, BTN_REMOVE_PKG
#	dlg_msg_box, dlg_yesno_box, dlg_get_password, dlg_password_error
#
#	dlg_show_log, dlg_save_log
#
#	dlg_isim_full, dlg_isim_core, dlg_isim_compare, dlg_show_progress
#	dlg_rsim, dlg_remove_progress
#	dlg_get_pkg, dlg_pkg_search
#
#	dlg_mtsim, dlg_maintenance_progress,
#	dlg_update, dlg_upgrade, dlg_upgrade_progress
#	dlg_check_apt_cache, dlg_check_apt_cache
#
#	dlg_main
#
# DEBIAN VERSION

# general buttons, icons and yad exitcode for EMC
source "$_BASEDIR/install/procedures/app_installer/app_button.conf"

# dialog instances
readonly inst_dlg_appinstaller="EMC_appinstaller_dlg"

# columns in dlg_main
readonly DLG_COLS=8
# selection in dlg_main
DLG_SELECTION=""
DLG_APPS=()

INSTALL_SIMULATED="false"

dlg_msg_box() {

	local title="${1:-info}" msg="$2" width="${3:-400}"

yad --name="$inst_dlg_appinstaller" \
--info \
--title="EMC app installer - $title" \
--window-icon="$i_msg" \
--center \
--width="$width" \
--text="<b>\n $msg</b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK)" \
--buttons-layout=center
}


dlg_yesno_box() {

local title="${1:-yesno}" msg="$2" width="${3:-400}"

yad --name="$inst_dlg_appinstaller" \
--info \
--title="EMC app installer - $title" \
--window-icon="$i_question" \
--center \
--width="$width" \
--text="<b>\n $msg</b>" \
--fontname="Monospace 12" \
--button="$(BTN_APPLY YES)" \
--button="$(BTN_CANCEL NO)" \
--buttons-layout=center
}

dlg_get_password() {

	local passwd="" exitcode action="$1" trial=$2

passwd=$(yad --name="$inst_dlg_appinstaller" \
--entry --width=350 \
--title="Authentication $trial. trial from 3" \
--window-icon="$i_password" \
--text="Enter Password for $action:" \
--button="$(BTN_OK)" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center)

	exitcode=$?
	echo "$passwd"
	return $exitcode
}

dlg_password_error() {

	local action=${1:-"process"}

yad --name="$inst_dlg_appinstaller" \
--title=" Password error" \
--window-icon="$i_error" \
--center \
--text="<b>\n\n3 incorrect password attempts. $action aborted.</b>" \
--button="$(BTN_OK)" \
--buttons-layout=center
}

dlg_show_log() {

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="$title log" \
--window-icon="$i_msg" \
--fontname="Monospace 12" \
--width=750 \
--height=500 \
--show-cursor \
--button="$(BTN_SAVE)" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center
}

dlg_save_log() {

local logfile="$1" yad_exitcode

logfile=$(LANG=C yad --name="$inst_dlg_appinstaller" \
--file-selection \
--save \
--confirm-overwrite \
--title="Save Log: Choose your name and directory" \
--window-icon="$i_save" \
--filename="$logfile" \
--width=800 --height=600 \
--button="$(BTN_OK)" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center)

yad_exitcode=$?

echo "$logfile"
}

dlg_is_dirty() {

local pkg="$1"

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC INSTALL ⚠️ package warning *$pkg*" \
--width=800 --height=600 \
--window-icon="$i_install" \
--text="<b> probably unwanted packages</b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK)" \
--button=" don't show this dialog again!$i_trash:$yad_cancel" \
--buttons-layout=center

}

dlg_isim_full(){

local pkg="$1"

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC INSTALL simulate FULL install for *$pkg*" \
--width=800 --height=600 \
--window-icon="$i_install" \
--text="<b>review apt output before proceeding:</b>" \
--fontname="Monospace 12" \
--button="$(BTN_INSTALL_PKG)" \
--button=" Simulate CORE install!$i_redo:$yad_core_sim" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center

#--button=" FULL INSTALL!$_ICONDIR/emc-package-install.png:$yad_full_install" \
#--button=" Simulate CORE install!$_ICONDIR/emc-redo.png:$yad_core_sim" \
#--button=" CANCEL!$_ICONDIR/emc-cancel.png:$yad_cancel" \

}

dlg_isim_core() {

local pkg="$1"
local txt=" show full log to compare and CONTINUE"

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC INSTALL simulate CORE install for *$pkg*" \
--width=800 --height=600 \
--window-icon="$i_install" \
--text="<b>review apt output before proceeding:</b>" \
--fontname="Monospace 12" \
--button="$(BTN_INSTALL_PKG CORE $yad_core_install)" \
--button="$txt!$i_ok:$yad_compare_log" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center

#--button=" CORE INSTALL!$_ICONDIR/emc-package-install.png:$yad_core_install" \
#--button=" show full log to compare and CONTINUE!$_ICONDIR/emc-ok.png:$yad_compare_log" \
#--button=" CANCEL!$_ICONDIR/emc-cancel.png:$yad_cancel" \

}

dlg_isim_compare() {

local txt="$1" pkg="$2"

echo "$txt" | yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC INSTALL compare FULL and CORE  install simulation for *$pkg*" \
--width=800 --height=600 \
--window-icon="$i_install" \
--text="<b>review apt output before proceeding:</b>" \
--fontname="Monospace 12" \
--button="$(BTN_INSTALL_PKG)" \
--button="$(BTN_INSTALL_PKG CORE $yad_core_install)" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center

#--button=" FULL INSTALL!$_ICONDIR/emc-package-install.png:$yad_full_install" \
#--button=" CORE INSTALL!$_ICONDIR/emc-package-install.png:$yad_core_install" \
#--button=" CANCEL!$_ICONDIR/emc-cancel.png:$yad_cancel" \

}

dlg_show_progress() {

local title="$1" text="$2" icon=${3:-$i_install}

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title=" $title " \
--width=800 --height=600 \
--window-icon="$icon" \
--text="<b> $text </b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK)" \
--buttons-layout=center \
--tail \
--auto-scroll
#--button=" OK!$_ICONDIR/emc-ok.png:0" \

}

dlg_rsim() {

local pkg="$1"

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC REMOVE Simulation for *$pkg*" \
--width=800 --height=600 \
--window-icon="$i_trash" \
--text="<b>❗EXAMINE output from apt purge --autoremove before proceeding:</b>" \
--fontname="Monospace 12" \
--button="$(BTN_CANCEL)" \
--button="$(BTN_APPLY "REMOVE NOW")" \
--buttons-layout=center

#--button="CANCEL!gtk-cancel:$yad_cancel" \
#--button=" REMOVE NOW!gtk-apply:$yad_remove" \
}

dlg_remove_progress() {

local pkg="$1"

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC REMOVE progress" \
--width=800 --height=600 \
--window-icon="$i_trash" \
--text="<b>Removing package: $pkg...</b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK)" \
--buttons-layout=center \
--tail \
--auto-scroll
#--button=" OK!$_ICONDIR/emc-ok.png:0" \

}

dlg_get_pkg() {

	local action=${1:-"install"} pkg="" 

pkg=$(yad --name="$inst_dlg_appinstaller" \
--entry --width=350 \
--title="EMC App Installer" \
--window-icon="$i_software" \
--text="Input package to $action:" \
--button="$(BTN_OK)" \
--buttons-layout=center)

	echo "$pkg"
}

dlg_pkg_search() {

	local -r l_yad_remove=20
	local f_input=$(mktemp)
	local f_output=$(mktemp /tmp/emc_search_result_XXXXXX)
	printf "%s\n" "$@" > "$f_input"

yad --name="$inst_dlg_appinstaller" \
--list \
--checklist \
--separator="|" \
--window-icon="$i_search" \
--title="search for $search_pkg: $num_pkg packages found $num_installed installed" \
--width=900 --height=600 \
--column="chk" \
--column="package" \
--column="state" \
--column="description" \
--button="$(BTN_INSTALL_PKG " ")" \
--button="$(BTN_REMOVE_PKG "" $l_yad_remove)" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center \
< "$f_input" > "$f_output"

#--button="$(BTN_INSTALL_PKG " ")" \
#--button=" Install!$i_install:$yad_full_install" \
#--button=" Remove!$i_remove_pkg:$yad_remove" \

exitcode=$?

rm -f "$f_input"
echo "$f_output"
return $exitcode
}

dlg_mtsim() {

local task="$1" btn_txt=" run AUTOREMOVE"
local infix_txt="apt autoremove"

if [ "$task" = "fixbroken" ]; then
	btn_txt=" run FIXBROKEN"
	infix_txt="apt --fix-broken install"
fi

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC MAINTAINANCE Simulation for *$task*" \
--width=800 --height=600 \
--window-icon="$i_trash" \
--text="<b>Please EXAMINE output from $infix_txt before proceeding:</b>" \
--fontname="Monospace 12" \
--button="$(BTN_CANCEL)" \
--button="$(BTN_APPLY "$btn_txt")" \
--buttons-layout=center
#--button="CANCEL!gtk-cancel:$yad_cancel" \
#--button="$btn_txt!gtk-apply:$yad_remove" \

}

dlg_maintenance_progress() {

local task="$1"

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC MAINTAINANCE progress" \
--width=800 --height=600 \
--window-icon="$i_trash" \
--text="<b>running $task...</b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK)" \
--buttons-layout=center \
--tail \
--auto-scroll
#--button=" OK!$_ICONDIR/emc-ok.png:0" \

}

dlg_update() {
yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC UPDATE" \
--width=800 --height=600 \
--window-icon="$i_update" \
--text="<b>Wait while apt update is running ...</b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK Continue)" \
--buttons-layout=center
#--button=" Continue!$_ICONDIR/emc-ok.png:0" \

}

dlg_upgrade() {
yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="EMC INSTALL VERIFICATION" \
--width=800 --height=600 \
--window-icon="$i_update" \
--text="<b>review upgradable packages before upgrade:</b>" \
--fontname="Monospace 12" \
--button=" UPGRADE NOW!$i_refresh:$yad_upgrade" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center
#--button=" CANCEL!$_ICONDIR/emc-cancel.png:$yad_cancel" \

}

dlg_upgrade_progress() {

yad --name="$inst_dlg_appinstaller" \
--text-info \
--title="UPGRSDE PROGRESS" \
--width=800 --height=600 \
--window-icon="$i_update" \
--text="<b>running apt upgrade ...</b>" \
--fontname="Monospace 12" \
--button="$(BTN_OK)" \
--buttons-layout=center \
--tail \
--auto-scroll
}

dlg_check_apt_cache() {

local duration="$1"

dlg_yesno_box "EMC PERFORMANCE CHECK" "$(txt_bad_cache)" 450
}

dlg_maintenance() {

local choice action ifs_save exitcode

# Using --list for a clean, stable selection instead of a complex form
choice=$(yad --name="$inst_dlg_appinstaller" \
--title="EMC app installer - Maintenance" \
--window-icon="$i_sys" \
--height=300 --width=400 \
--center \
--text="<b>Select what to do:</b>" \
--list \
--column="Action":TEXT --column="Description":TEXT \
"<b>autoremove</b>" "<i>Uninstall unused dependencies</i>" \
"<b>fixbroken</b>" "<i>Fix broken dependencies</i>" \
"" "" \
"<b>update</b>" "<i>update/upgrade packages</i>" \
"<b>autoclean</b>" "<i>Remove outdated packages from apt cache</i>" \
"<b>clean</b>" "<i>Remove ALL packages from apt cache</i>" \
"" "" \
"<b>check apt cache</b>" "<i>Check if apt cache is corrupted</i>" \
--button="$(BTN_OK)" \
--button="$(BTN_CANCEL)" \
--buttons-layout=center)

exitcode=$?

# Return the selected action (first column) without tags
ifs_save="$IFS"
IFS="|" read -r action _ <<< "$choice"
IFS="$ifs_save"

action="${action#<b>}"
action="${action%</b>}"

echo "$action"

return $exitcode
}

dlg_main() {

DLG_SELECTION=""

DLG_SELECTION=$(yad --name="$APP_INSTALLER_INSTANCE" \
--list \
--title=" EMC App Installer" \
--text=" scroll up/down right/left" \
--window-icon="emc-software-installer" \
--width=650 --height=700 \
--checklist --column="" --column="Package" --column="Keyword" --column="Suggestion" --column="State" --column="ENV" --column="Description" --column="Comment" \
"${DLG_APPS[@]}" \
--button=" Clear!$i_undo!refresh screen:10" \
--button=" Install!$i_install!install selected software:20" \
--button=" Remove!$i_remove_pkg!remove installed software:30" \
--button=" Search!$i_search!search for not listed software:40" \
--button=" System!$i_sys!get system report:50" \
--button=" Service!$i_refresh!update, repair cache ...:60" \
--button=" Speed!$i_sysrun!measure download speed:70" \
--button=" Feedback!emc-mail-sent!send feedback to developer:80" \
--button=" Exit!$i_exit:1" \
--buttons-layout=center)
}
