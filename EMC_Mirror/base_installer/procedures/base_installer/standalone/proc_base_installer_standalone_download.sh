#!/bin/bash

# EMC_standalone_base_installer - download procedures:
#
#	run_standalone_download_simulation
#	can_download, run_standalone_installation
#
# DEBIAN VERSION

get_download_speed() {

	DOWNLOAD_SPEED=""
	[ "$INET_CONNECTED" = "false" ] && return $EMC_error

	local terminal="$TERM" download_speed errcode
	local logfile=$(mktemp)
	#URL="https://speed.cloudflare.com/__down?bytes=10000000"
	URL="http://cachefly.cachefly.net/10mb.test"

	trap 'rm -f "$logfile"' RETURN

	TERM=ansi
	info_box "" "\n\n   running download speed test ..." 9	40
	LC_ALL=C wget -4 -c --show-progress --progress=bar:force -O /dev/null "$URL" -o "$logfile"
	errcode=$?
	TERM="$terminal"
	[ $errcode -ne 0 ] && return $errcode

	download_speed=$(grep -oE '[0-9.]+[[:space:]]+[A-Z]B/s' "$logfile" | tail -n 1)
	DOWNLOAD_SPEED=$(echo "$download_speed" | cut -d" " -f1)

	return 0
}

get_download_size() {

	local size

	size=$(LC_ALL=C apt-get install -y "${INSTALL_PACKAGES[@]}" --print-uris | grep -E "Need to get|disk space" | head -n 1)

	DOWNLOAD_SIZE=$(echo "$size" | cut -d" " -f4)
	[ -z "$size" ] && DOWNLOAD_SIZE=0
}

calc_download_duration() {

	[ $DOWNLOAD_SIZE -eq 0 ] && return $EMC_error
	[ -z "$DOWNLOAD_SPEED" ] && return $EMC_error

	# Split speed into integer and fraction (e.g., 2.25 -> 2 and 25)
	local speed_int=$(echo "$DOWNLOAD_SPEED" | cut -d. -f1)
	local speed_frac=$(echo "$DOWNLOAD_SPEED" | cut -d. -f2)
	
	# Handle cases without decimal point
	[ -z "$speed_frac" ] && speed_frac=0
	# Ensure fraction is treated correctly if it has only one digit
	[ ${#speed_frac} -eq 1 ] && speed_frac="${speed_frac}0"
	
	# Create scaled integer (e.g., 225)
	local speed_scaled=$(( (speed_int * 100) + speed_frac ))
	
	# Avoid division by zero
	[ "$speed_scaled" -eq 0 ] && return

	# Calculate duration: (Size * 100) / SpeedScaled
	local duration=$(( (DOWNLOAD_SIZE * 100) / speed_scaled ))
	
	echo $duration
}

can_download() {

	local errcode=$EMC_ok

	check_inet
	if [ "$EMC_running" = "true" ]; then
		msg_box "" "$MSG_EMC_RUNNING"
			errcode=$EMC_runerr
	elif [ "$INET_CONNECTED" = "false" ]; then
		msg_box "" "$MSG_NOT_CONNECTED"
		errcode=$EMC_runerr
	elif [ -z "$EMC_passwd" ]; then
		! get_passwd && errcode=$EMC_pwerr
	fi

	return $errcode
}

run_standalone_download_simulation() {
	local errcode
	
	can_download
	errcode=$?

	if [ $errcode -ne $EMC_ok ]; then
		on_error $errcode
		return
	fi

	local now=$(date -R) line=""
	local logcontent="" 

	echo -e "### EMC DOWNLOAD SIMULATION $now ###\n\n" > "$TMP_LOG" 
	sys_header >> "$TMP_LOG" 

	echo -e "### TOTAL DOWNLOAD SIZE estimated ###\n" >> "$TMP_LOG"
	LC_ALL=C apt-get install -y "${INSTALL_PACKAGES[@]}" --print-uris | grep -E "Need to get|disk space" | sed '$d'>> "$TMP_LOG"

	[ $DOWNLOAD_SIZE -eq 0 ] && get_download_size
	get_download_speed
	estimated_time=$(calc_download_duration)
	duration=$(date -u -d "@$estimated_time" +"%Mm %Ss")

	echo -e "\nDownload speed: $DOWNLOAD_SPEED MB/s estimated duration: $duration" >> "$TMP_LOG"

	show_log "simulate download" "$TMP_LOG"
	logcontent="\n$(cat "$TMP_LOG")"

	save_log "download_sim" "$logcontent"
}

do_download() {

	SIMULATION="false"

	local terminal="$TERM"
	local now=$(date -R) line=""
	local info_txt="$(get_standalone_package_info)"
	local install_log="" logcontent="" simulation_txt=""
	local syslog_minimal syslog_base estimated_time
	local header="$(mktemp)"

	[ $DOWNLOAD_SIZE -eq 0 ] && get_download_size
	get_download_speed
	estimated_time=$(calc_download_duration)

	> "$TMP_LOG"

	TERM=ansi

	if ! full_confirmation_box "DOWNLOAD info" "$(download_note "$estimated_time")$info_txt"; then
		TERM="$terminal"
		clear
		return 1
	fi

	echo "### EMC DOWNLOAD BEGIN $now ###" > "$header" 
	sys_header >> "$header" 

	echo -e "Download packages :\n\n   see DOWNLOAD log after DOWNLOAD END\n" >> "$header" 

	download_standalone_packages "${INSTALL_PACKAGES[@]}"

	TERM="$terminal"
	clear

	now=$(date -R)
	echo -e "### EMC DOWNLOAD END   $now ###\n" >> "$header" 
	echo -e "\n########## DOWNLOAD LOG ##########\n" >> "$header" 

# DEBUG
#logcontent="$(cat "$TMP_LOG")"
#save_log "download_raw_output_$now" "$logcontent"

	# obsolete now ? 
	setup_install_log "$header" "$TMP_LOG" "DOWNLOAD"

	show_log "download" "$TMP_LOG"
	logcontent="\n$(cat "$TMP_LOG")"

	save_log "download_$now" "$logcontent"

	check_install
	DOWNLOAD_SUCCESS="true"
}

run_standalone_download() {

	local errcode
	
	can_download
	errcode=$?

	if [ $errcode -ne $EMC_ok ]; then
		on_error $errcode
		return
	fi
	[ "$DOWNLOAD_SIZE" -eq 0 ] && get_download_size
	do_download
}

download_standalone_packages() {

	[ "$EMC_running" = "true" ] && return $EMC_runerr

	local pkg logcontent="" now=$(date -R) flags
	local estimated_time=$(calc_download_duration)
	local estimated_duration=$(date -u -d "@$estimated_time" +"%Mm %Ss")

	> "$TMP_LOG"
	echo -e "### download_standalone_packages $now\n\n" >> "$TMP_LOG"

	exec 3>&2

	local start_time stop_time download_start download_stop duration

	echo -ne "\r\033[Kfirst running apt update ..." >&3
	start_time=$(date +%s)
	LC_ALL=C sudo -S <<< "$EMC_passwd" apt update >> "$TMP_LOG" 2>&1
	download_stop=$(date +%s)
	echo -e "\n" >> "$TMP_LOG"

	# download all packages as full packages with install recommends
	duration=$((download_stop - start_time))
	echo -ne "\r\033[Kapt update done in $duration sec. starting download now. this will take about $estimated_duration sec ..." >&3
	echo -e "### full pkgs: $full_pkgs  ###\n" >> "$TMP_LOG"
	sleep 1
	download_start=$(date +%s)

local timer_pid
(
	local timer=0 time_estimated=$estimated_time
	while true; do
		echo -ne "\r\033[Krunning download ...          elapsed: [ ${timer} / ${time_estimated} ] sec" >&3
		((timer++))
		sleep 1
	done
) &
timer_pid=$!


	LC_ALL=C sudo -E -S <<< "$EMC_passwd" /usr/bin/apt-get install -q --download-only --fix-missing -o Dir::Cache::Archives="$DOWNLOAD_DIR" -y "${INSTALL_PACKAGES[@]}" >> "$TMP_LOG" 2>&1
	stop_time=$(date +%s)
	echo -e "\n\n" >> "$TMP_LOG"

kill $timer_pid
wait $timer_pid 2>/dev/null

	stop_time=$(date +%s)
	duration=$((stop_time - start_time))
	echo -ne "\r\033[Kall packages downloaded in $duration sec." >&3
	sleep 2
	exec 3>&-

	now=$(date -R)
	echo -e "### download_standalone_packages done in $duration sec. $now\n\n" >> "$TMP_LOG"
}

download_debian_iso() {
	local base_url="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/"
	[ -z "$DEBIAN_ISO" ] && DEBIAN_ISO=$(wget -qO- "$base_url" 2>&1 /dev/null | grep -oE 'debian-[0-9.]+-amd64-netinst\.iso' | head -n 1)
	local iso_url="${base_url}${DEBIAN_ISO}"
	local target_iso="$DOWNLOAD_DIR/$DEBIAN_ISO"
	local exitcode

	[ -z "$DEBIAN_ISO" ] && return 6
	[ -f "$target_iso" ] && ISO_DOWNLOAD="true"
	[ -f "$target_iso" ] && return 0

	# -4 forces IPv4 connections
	# LC_ALL=C forces wget to draw the progress bar in standard ASCII format.
	sudo -E LC_ALL=C wget -4 --show-progress -O "$target_iso" "${base_url}${DEBIAN_ISO}" -o "$DOWNLOAD_DIR/$DEBIAN_ISO.log"

	exitcode=$?
	[ $exitcode -eq 0 ] && ISO_DOWNLOAD="true"
	[ $exitcode -ne 0 ] && rm -f "$target_iso"
	return $exitcode
}

verify_debian_iso() {

	[ -z "$ISO_DOWNLOAD" ] && return
	
	local base_url="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/"
	local target_iso="$DOWNLOAD_DIR/$DEBIAN_ISO"
	local checksum_file="SHA256SUMS"

	# load chksum file
	sudo -E wget -4 -q "$base_url$checksum_file" -O "$DOWNLOAD_DIR/$checksum_file" || return $?

	cd "$DOWNLOAD_DIR"
	
	sha256sum -c --status --ignore-missing "$checksum_file"
	
	local verify_status=$?

	[ $verify_status -eq 0 ] && ISO_DOWNLOAD_SUCCESS="true"

	rm -f "$checksum_file"

	return $verify_status
}

run_iso_download() {

	[ ! -z "$ISO_DOWNLOAD_SUCCESS" ] && return

	local terminal="$TERM" exitcode

	[ -z "$EMC_passwd" ] && get_passwd
	[ -z "$EMC_passwd" ] && return

	echo "$EMC_passwd" | sudo -S -v > /dev/null 2>&1

	TERM=ansi
	info_box "" "\n\n   Download iso is running ..." 10
	echo " "
	download_debian_iso
	exitcode=$?
	info_box "" "\n\n   Verifying iso ..." 10
	[ $exitcode -eq 0 ] && verify_debian_iso
	exitcode=$?
	TERM="$terminal"

	if [ $exitcode -eq 0 ]; then
		msg_box "sucess" "$(msg_download_sucess)" 12
	elif [ ! -z "$ISO_DOWNLOAD" ]; then
		rm -f "$DOWNLOAD_DIR/$DEBIAN_ISO"
		msg_box "error" "debian netinst iso corrupt. iso removed" 10
	fi
}

check_usb_devices() {
	local devices num_devices msg errcode=$EMC_ok

	devices=$(lsblk -o NAME,MODEL,SIZE,RM,TYPE,TRAN -n --pairs | grep 'TRAN="usb"' | grep 'TYPE="disk"')
	num_devices=$(echo "$devices" | wc -l)

	[ -z "$devices" ] && ((num_devices--))

 	if [ $num_devices -eq 1 ]; then
		USB_DEV="/dev/$(echo -e "$devices" | cut -d' ' -f1 | cut -d'"' -f2)"
		local iso_size=$(stat -c%s "$DOWNLOAD_DIR/$DEBIAN_ISO")
		local stick_size=$(lsblk -bno SIZE "$USB_DEV" | head -n 1)
		if [ "$iso_size" -gt "$stick_size" ]; then
			msg_box "Error: " "USB drive is too small for the selected ISO." 10 40
			return $EMC_error
		fi
		msg_box "device for iso dump" "$(echo -e "$devices" | cut -d' ' -f1,2,3,4)" 10 60
	else
	[ $num_devices -eq 0 ] && msg_box "" "No USB drive found. Insert USB drive and continue." 10 40
	[ $num_devices -gt 1 ] && msg_box "" "$(echo -e "$devices" | cut -d' ' -f1,2,3,4)$MSG_REMOVE_DEV" 17 60
	[ $num_devices -ne 1 ] && errcode=$EMC_error
	fi

	return $errcode
}

calc_write_duration() {
	
	local file="$DOWNLOAD_DIR/$DEBIAN_ISO"
	local file_size=$(stat -c %s "$file") errcode
	local file_size_mb=$((file_size / 1048576)) speed_mb
	local start_time=$(date +%s)

	# Warm-up to initialize the controller state
	sudo -n dd if=/dev/zero of="$USB_DEV" bs=1M count=8 conv=fdatasync status=none >/dev/null 2>&1
	sync
	#sudo -n LC_ALL=C dd if=/dev/zero of="$USB_DEV" bs=1M count=25 oflag=dsync
	sudo -n LC_ALL=C dd if=/dev/zero of="$USB_DEV" bs=1M count=25 conv=fdatasync
	sync
	local stop_time=$(date +%s)
	local duration=$((stop_time - start_time))
	local write_duration=$(( (file_size_mb / 25) * duration ))

	# Calculate final estimate with a 2x multiplier to account for the speed drop
	# after the USB cache is exhausted
	echo $(( write_duration * 2 ))
}

write_iso() {

	local estimated_time="$1"

	echo "$EMC_passwd" | sudo -S -v > /dev/null 2>&1
	local LOG="/tmp/emc_write.log"
	local errcode=$EMC_ok

	# We use 'status=progress' redirected to stderr, so the user still sees the progress,
	# but all other potential errors go to the log file.
	echo -ne "\r\033[Kwriting iso to ${USB_DEV} ..." >&3
	
local timer_pid
(
	local timer=0 time_estimated=$estimated_time
	while true; do
		echo -ne "\r\033[Kwriting iso...          elapsed: [ ${timer} / ${time_estimated} ] sec" >&3
		((timer++))
		sleep 1
	done
) &
timer_pid=$!

	local start_time=$(date +%s)
	sudo -E LC_ALL=C dd if="$DOWNLOAD_DIR/$DEBIAN_ISO" of="${USB_DEV}" bs=4M status=none conv=fsync 2>/dev/null
	errcode=$?

kill $timer_pid
wait $timer_pid 2>/dev/null

	if [ $errcode = $EMC_ok ]; then
		sync
		local stop_time=$(date +%s)
		msg_box "Success" "Installation medium created in $((stop_time - start_time)) sec." 10 
	else
		msg_box "Error" "Writing failed." 10 40
		errcode=$EMC_error
	fi

	return $errcode
}

run_write_iso() {

	[ -z "$ISO_DOWNLOAD_SUCCESS" ] && msg_box "Error" "Get netinst.iso first." 10
	[ -z "$ISO_DOWNLOAD_SUCCESS" ] && return

	local terminal="$TERM" exitcode duration

	check_usb_devices
	exitcode=$?
	[ $exitcode -ne $EMC_ok ] && return

	yesno_box "" "$MSG_WRITE_ISO"
	exitcode=$?
	[ $exitcode -ne $EMC_ok ] && return

	[ -z "$EMC_passwd" ] && get_passwd
	[ -z "$EMC_passwd" ] && return

	echo "$EMC_passwd" | sudo -S -v > /dev/null 2>&1

	sudo -E LC_ALL=C fuser -k "${USB_DEV}"* > /dev/null 2>&1
	sudo -E LC_ALL=C umount "${USB_DEV}"* > /dev/null 2>&1

	TERM=ansi

	info_box "" "try to calc duration ..."
	duration=$(calc_write_duration)

	info_box "Writing to usb device" "$(msg_write_usb "$duration")"
	echo " "
	exec 3>&2
	write_iso $duration
	exec 3>&-
	TERM="$terminal"

}
