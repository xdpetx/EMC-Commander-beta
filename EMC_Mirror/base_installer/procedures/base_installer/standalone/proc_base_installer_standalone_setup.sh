#!/bin/bash

# EMC_standalone_base_installer - setup procedures:
#
#	setup_desktop
#	setup_keyboard, setup_sources, setup_plocate
#	finish_setup
#
# DEBIAN VERSION

setup_desktop() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return

	echo -ne "\r\033[Krunning setup_desktop ..." >&2
	echo -e "setup_desktop:\n"

	if [ "$SIMULATION" = "true" ]; then
		echo -e "   setup i3_EMC desktop environment\n"
		return
	fi

	local INSTALL_DIR="$HOME/.config/polybar/install"

	# i3_EMC Desktop registration
	sudo -S <<< "$EMC_passwd" mkdir -p "/usr/share/xsessions/"
	sudo -S <<< "$EMC_passwd" rm -f /usr/share/xsessions/i3.desktop
	sudo -S <<< "$EMC_passwd" rm -f /usr/share/xsessions/i3-with-shmlog.desktop
	sudo -S <<< "$EMC_passwd" cp "$INSTALL_DIR/emc/i3_EMC.desktop" "/usr/share/xsessions/"

	# create .xinit.rc for startx
	cp "$INSTALL_DIR/emc/xinitrc_EMC" "$HOME/.xinitrc"
	
	echo -e "\n   setup Standalone EMC done\n"
}

setup_filemanager() {

	local INSTALL_DIR="$HOME/.config/polybar/install"
	local CONFIG_SPACEFM="/etc/spacefm/spacefm.conf"
	local CONFIG_INI="$HOME/.config/polybar/config.ini"
	local APP_INI="$HOME/.config/polybar/usr/applications.ini"
	local TOOLTIP_INI="$HOME/.config/polybar/usr/tooltips.ini"
	local fm_base="${FM_BASE[0]}"
	local fm_cmd app_dir script_file f line 

	case "$fm_base" in
		pcmanfm)	fm_cmd="pcmanfm -n"
					app_dir="menu://applications/";;
		spacefm)	mkdir -p "$HOME/Applications"
					$HOME/.config/polybar/script/setup_fm_applications.sh
					fm_cmd="spacefm -n"
					app_dir="\$HOME/Applications"
					sudo -S <<< "$EMC_passwd" cp -v "$INSTALL_DIR/emc/spacefm_conf_EMC" "$CONFIG_SPACEFM"
					sed -i 's/^search01_left.*/search01_left = spacefm -f/' "$APP_INI"
					sed -i 's/^t_search01_left.*/t_search01_left = spacefm -f/' "$TOOLTIP_INI" 
					rm -rf "$HOME/.config/pcmanfm";;
		konqueror)	mkdir -p "$HOME/Applications"
					fm_cmd="konqueror --new-window"
					app_dir="\$HOME/Applications"
					rm -rf "$HOME/.config/pcmanfm";;
		dolphin)	mkdir -p "$HOME/Applications"
					fm_cmd="dolphin --new-window"
					app_dir="\$HOME/Applications"
					rm -rf "$HOME/.config/pcmanfm";;
	esac

	for f in home emc music office; do
		script_file="$HOME/.config/polybar/usr/script/launch_fm_$f.sh"
		# Find the line number of "# start filemanager"
		line=$(grep -n "# start filemanager" "$script_file" | cut -d: -f1)

		if [ "$f" = "home" ]; then
			# Replace line + 1 with fm_cmd.
			sed -i "$((line + 1))c\\$fm_cmd \\\\" "$script_file"
			# Replace line + 2 with app_dir.
			sed -i "$((line + 2))c\\\"$app_dir\" \\\\" "$script_file"
		else
			sed -i "$((line + 1))c\\$fm_cmd \\\\" "$script_file"
		fi
	done

	line=$(grep -n "# native filemanager do not edit!" "$CONFIG_INI" | cut -d: -f1)

	sed -i "$((line + 1))c\EMC_FM = $fm_base" "$CONFIG_INI"
}

setup_keyboard() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return

	echo -ne "\r\033[Krunning setup_keyboard ..." >&2
	echo -e "setup_keyboard:\n"

	local lang="${SYSTEM_LOCALE%%_*}"

	if [ "$SIMULATION" = "true" ]; then
		echo -e "   will setup keyboard specific files for $lang\n"
	else
		local APP_INI="$HOME/.config/polybar/usr/applications.ini"
		local CONF_USRCMD="$HOME/.config/i3/usr/config_usercommands"
		local conf01="exec_always --no-startup-id setxkbmap -layout" conf02

		case "$lang" in
			us)	conf02="$conf01 us,es,fr,de -option 'grp:alt_shift_toggle'" ;;
			es) conf02="$conf01 es,us,it,fr -option 'grp:alt_shift_toggle'" ;;
			fr) conf02="$conf01 fr,us,es,it -option 'grp:alt_shift_toggle'" ;;
			*)	conf02="$conf01 $lang,us,es,fr -option 'grp:alt_shift_toggle'" ;;
		esac

		sed -i "s|^$conf01.*|$conf02|" "$CONF_USRCMD"
		sed -i "s/^locale.*/locale = $SYSTEM_LOCALE/" "$APP_INI"
		
		echo -e "   setup keyboard done\n"
	fi
}

# apt sources for packages
setup_sources() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return
	[ "$SIMULATION" = "true" ] && return

	echo -ne "\r\033[Ksetup extended sources.list ..." >&2
	echo -e "   Setup extended sources for apt ...\n"

	# Preserve original formatting by copying verified files
	local install_dir="$HOME/.config/polybar/install/emc"
	local source_list="$install_dir/sources_EMC.list"
	local source_key="$install_dir/fasttrack-archive-keyring_EMC.gpg"
	local target_list="/etc/apt/sources.list"
	local target_key="/usr/share/keyrings/fasttrack-archive-keyring.gpg"

	echo -e "   orgininal sources list backed up in $HOME/EMC_Backup/sources.list.bak"
	cp "$target_list" "$HOME/EMC_Backup/sources.list.bak"

	# Use sudo with your password variable from the script
	sudo -S <<< "$EMC_passwd" cp "$source_list" "$target_list"
	sudo -S <<< "$EMC_passwd" cp "$source_key" "$target_key"

	LC_ALL=C sudo -S <<< "$EMC_passwd" apt update 2>&1
}

# plocate search functions
setup_plocate() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return
	[ "$SIMULATION" = "true" ] && return

	echo -ne "\r\033[KInitialize plocate search database ..." >&2
	echo -e "   Initialize plocate search database ...\n"

	local source="$HOME/.config/polybar/install/emc/plocate-updatedb_emc.timer"
	local dest="/lib/systemd/system/plocate-updatedb.timer"

	# Copy the customized timer file to system context
	sudo -S <<< "$EMC_passwd" cp "$source" "$dest"

	# Reload systemd manager configuration to recognize the new file
	sudo -S <<< "$EMC_passwd" systemctl daemon-reload 2>&1

	# Enable and arm the timer for upcoming system boots
	sudo -S <<< "$EMC_passwd" systemctl enable plocate-updatedb.timer 2>&1

	# Build initial search database immediately (only needed once)
	sudo -S <<< "$EMC_passwd" updatedb 2>&1
}

# reduce timeout waiting
setup_timeout() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return
	[ "$SIMULATION" = "true" ] && return

	# Optimize systemd timeouts to prevent long shutdown and boot delays
	if [ -f "/etc/systemd/system.conf" ]; then
		# Use a temporary file to prepare the configuration
		local tmp_conf=$(mktemp)
		cp /etc/systemd/system.conf "$tmp_conf"

		# Modify the configuration in the temporary file
		# We use sed to handle both commented and active settings
		sed -i 's/^#\?DefaultTimeoutStartSec=.*/DefaultTimeoutStartSec=15s/' "$tmp_conf"
		sed -i 's/^#\?DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=5s/' "$tmp_conf"
		sed -i 's/^#\?DefaultDeviceTimeoutSec=.*/DefaultDeviceTimeoutSec=10s/' "$tmp_conf"
		sed -i 's/^#\?DefaultTimeoutAbortSec=.*/DefaultTimeoutAbortSec=10s/' "$tmp_conf"

		# Move the prepared file back with a single sudo operation
		sudo -S <<< "$EMC_passwd" cp "$tmp_conf" /etc/systemd/system.conf
		rm "$tmp_conf"
	fi
}

finish_setup() {

	[ "$MINIMAL_SYSTEM" = "false" ] && return

	echo -ne "\r\033[Krunning finish_setup ..." >&2
	echo -e "finish_setup:\n"

	if [ "$SIMULATION" = "true" ]; then
		echo "$(finish_setup_simulation)"
		echo
		return
	fi

	# Make some directories for EMC if they do not exist
	mkdir -p "$HOME/EMC_Backup"
	mkdir -p "$HOME/Desktop"
	mkdir -p "$HOME/Pictures"
	mkdir -p "$HOME/.config/polybar/log"

	# extended sources for apt
	setup_sources

	# initialize plocate
	setup_plocate

	# reduce timeout waiting
	setup_timeout
	
	# setup selecte filemanager
	setup_filemanager

	echo -e "   Enable network interface ...\n"
	# Enable management of interfaces listed in /etc/network/interfaces
	sudo -S <<< "$EMC_passwd" sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf
	# group management
	sudo -S <<< "$EMC_passwd" usermod -aG cdrom,floppy,sudo,audio,dip,video,plugdev,users,netdev,bluetooth,lp,lpadmin,dialout,input "$USER" 2>&1

	# install flag
	local emc_install_flag="$HOME/.config/polybar/.EMC_install_flag"
	echo "EMC Install Flag. Do not remove!" > "$emc_install_flag"
	chmod 444 "$emc_install_flag"

	# setup monitor after first run
	echo "xrandr_fail = true" > "$HOME/.config/polybar/xrandr_fail"

	kernel_be_quiet

	echo -e "\n   Setup finished successfully.\n"
}
