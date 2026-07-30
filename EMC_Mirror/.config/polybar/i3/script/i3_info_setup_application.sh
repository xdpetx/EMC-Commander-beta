#!/bin/bash

#notify-send "setup_application.sh: script started"

SETUP_INFO=""
INFO_TITLE=" Setup Applications Info"
SETUP_INFO_FLAG="/tmp/polybar_setup_info.flag"

SETUP_INFO="
   Edit file applications.ini to start applications of your choice

      The [app-main]   section is for MAINBAR    : There you enter the launch commands for the icons in the right section of the mainbar.
      The [app-launch] section is for LAUNCHBAR  : There you enter the launch commands for the icons in the launch bar.
      The [app-data]   section is for DATA       : There you enter settings that modules or scripts can access.
      The [user-files] section is for FILE access: There you enter files that should be opened.

      [app-main]

      The modules in the mainbar respond to left/right clicks or double clicks.
      You can assign one start command to each click. Clicks that are not supposed to start a command are simply left blank:

      # configure modules to load
      main_modules_right = screenshot display pulseaudio keyboard cpu memory filesys eth wlan date i3_exit

      # define click actions for module cpu
      cpu_left = gnome-system-monitor -r
      cpu_right =
      cpu_dbl_left = cpu-x
      cpu_dbl_right =

      [app-launch]

      The modules in the launchbar only respond to single clicks with the left/right mouse button.

      # configure your launchbars with starters
      launchbar_left_modules_left = audio02 audio01 video01 video02 pic01
      launchbar_left_modules_right = launchbar_space03 dosbox01

      launchbar_center_modules_right = fm01 fm02 package02 user_space01 web01 mail01 download01 messenger01 user_space01 terminal01 editor01 search01 user_space01

      launchbar_right_modules_left = package01 settings01 bluetooth01 net01 printer01
      launchbar_right_modules_right = calendar01 calculator01 office01 pdftool01 scan01

      # configure click actions for starter web01
      web01_left = chromium
      web01_right = firefox

      # For more complex commands, use quotation marks, otherwise they may not be executed:
      fm01_left = $_USERSCRIPT/launch_fm_home.sh &
      fm01_right = $_USERSCRIPT/launch_fm_music.sh &

      user02_left = /mnt/linuxdata01/genymotion/player --vm-name Google Pixel 2
      user02_right =

      This section is structured according to the categories in xfce4-appfinder using comments.
      See also /usr/share/applications


      lookup in xfce4-appfinder for applications

      use the tooltips for more information.
      Right-click to edit the launcher and then copy the 
      corresponding command into the applications.ini file.

      See also the properties of desktop files in /usr/share/applications.

      when ready dbl click left on workspaces icon to close tmp workspace
"
#notify-send "$INFO_TITLE" "\n<tt>$SETUP_INFO</tt>"

dlg_setup_info() {

	echo -e "$SETUP_INFO" | yad --title="$INFO_TITLE" \
--text-info \
--back=#285577 \
--fore="#ffffff" \
--fontname="monospace 12" \
--window-icon="emc-info" \
--width=1250 \
--height=600 \
--fixed \
--center \
--borders=1 \
--button=" OK!emc-gtk-ok:0" \
--button=" EMC app installer!emc-software-installer!install software:10" \
--button=" Application setup!emc-gtk-edit!edit applications.ini and tooltips.ini:20" \
--buttons-layout center
}


show_setup_info() {

	local yad_exitcode

	echo "SETUP_INFO" > "$SETUP_INFO_FLAG"
	dlg_setup_info

	yad_exitcode=$?

	case $yad_exitcode in
		10) $_BASEDIR/install/EMC_standalone_app_installer.sh ;;
		20) xdg-open $_USERDIR/applications.ini &
#			sleep 01
			xdg-open $_USERDIR/tooltips.ini & ;;
	esac

	rm -f "$SETUP_INFO_FLAG"
}

[ -f "$SETUP_INFO_FLAG" ] && return

show_setup_info
