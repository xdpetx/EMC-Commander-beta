#!/bin/bash

# EMC_standalone_base_installer - install procedures:
#
#	get_packages_install_state
#	install_standalone_packages
#
# DEBIAN VERSION

get_packages_install_state() {
	local pkg_list=("$@")
	[ ${#pkg_list[@]} -eq 0 ] && return

	# 1. Check only the packages from the list (direct query)
	# This is significantly faster than forking a process for each package.
	#local installed_pkgs=$(dpkg-query -W -f='${Package}\n' "${pkg_list[@]}" 2>/dev/null)
	local installed_pkgs=$(dpkg-query -W -f='${Package} ${db:Status-Status}\n' "${pkg_list[@]}" 2>/dev/null | grep ' installed$' | cut -d' ' -f1)

	local pgk_install_state_list=()

	for pkg in "${pkg_list[@]}"; do
		# 2. Check if the package appears in the hit list of dpkg-query.
		if [[ "$installed_pkgs" =~ ^(.*$'\n')?"$pkg"($'\n'.*)?$ ]]; then
			pgk_install_state_list+=("installed")
		elif ls "$DOWNLOAD_DIR"/"$pkg"_*.deb 1> /dev/null 2>&1; then
            pgk_install_state_list+=("downloaded")
		else
			pgk_install_state_list+=("not_installed")
		fi
	done

	echo "${pgk_install_state_list[@]}"
}

install_standalone_packages() {

	local pkg logcontent="" now=$(date -R) flags
	local i=0 total=$#

	[ "$EMC_running" = "true" ] && return $EMC_runerr

	> "$TMP_LOG"
	echo -e "### install_standalone_packages $now\n\n" >> "$TMP_LOG"

	exec 3>&2

	for pkg in "$@"; do
		((i++))
		echo -ne "\r\033[Krun installation of [$i/$total]: $pkg" >&3
		echo -e "### pkg $pkg  ###\n" >> "$TMP_LOG"

		flags=""
		case "$pkg" in
			"cups"|"bluez"|"bluetooth"|"xserver-xorg-core"|"xserver-xorg")
				flags="--no-install-recommends" ;;
			"dunst"|"libnotify-bin"|"network-manager"|"debsecan")
				flags="--no-install-recommends" ;;
		esac

		LC_ALL=C sudo -E -S <<< "$EMC_passwd" /usr/bin/apt-get install -o Dir::Cache::Archives="$DOWNLOAD_DIR" -q ${flags} -y -- "$pkg" >> "$TMP_LOG" 2>&1

		echo -e "\n\n" >> "$TMP_LOG"
	done
	exec 3>&-

	echo -e "### install_standalone_packages done\n\n" >> "$TMP_LOG"
}
