#!/bin/bash

INET_CONNECTED=""
DOWNLOAD_SPEED=""
DOWNLOAD_SPEED_INSTANCE="EMC_chk_download_speed"

check_inet() {

	INET_CONNECTED=""
	
	# ping one of the root name servers
	! ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1 && return
	# verify connectivity
	! getent hosts debian.org > /dev/null 2>&1 && return

	INET_CONNECTED="true"
}

check_download_speed() {

	local logfile=$(mktemp) errcode
#	URL="https://speed.cloudflare.com/__down?bytes=10000000"
	URL="http://cachefly.cachefly.net/10mb.test"
#	URL="http://speedtest.tele2.net/10MB.zip"

	LC_ALL=C wget -4 -c --show-progress --progress=bar:force -O /dev/null "$URL" -o "$logfile"  2>&1 | tee "$logfile"

	errcode=${PIPESTATUS[0]}
	[ $errcode -ne 0 ] && notify-send "wget errcode = $errcode"

	DOWNLOAD_SPEED=$(grep -oE '[0-9.]+[[:space:]]+[A-Z]B/s' "$logfile" | tail -n 1)

	rm -f "$logfile"
}

dlg_download_progress() {

yad --name="$DOWNLOAD_SPEED_INSTANCE" \
--text-info \
--title="Download speed measure" \
--width=800 --height=600 \
--window-icon="emc-system-run" \
--fontname="Monospace 12" \
--button=" OK!emc-gtk-ok:0" \
--buttons-layout=center \
--tail \
--auto-scroll
#--button=" OK!$_ICONDIR/emc-ok.png:0" \

}

get_download_speed() {
	check_inet

	[ -z $INET_CONNECTED ] && return

	{ 
		check_download_speed
		echo -e "\nDOWNLOAD_SPEED = $DOWNLOAD_SPEED\n"
		echo "    DSL  6.000 = 0.75 MB/s"
		echo "    DSL 16.000 = 2.0  MB/s"
		echo "   VDSL 50.000 = 6.0  MB/s"
		echo -e "\ndone"
	} | dlg_download_progress

}

# first close all Info and Help notifies
dunstctl close-all

get_download_speed
