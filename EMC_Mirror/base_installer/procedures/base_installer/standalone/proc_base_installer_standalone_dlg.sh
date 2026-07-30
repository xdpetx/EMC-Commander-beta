#!/bin/bash

# EMC_standalone_base_installer - whiptail gui dialogs:
#
#	msg_box, text_box, full_text_box
#	yesno_box, full_confirmation_box
#	input_box
#	info_box, full_info_box
#
#	show_log
#	select_fm
#	main_menu
#
# DEBIAN VERSION


BTN_OK="[   OK   ]"
BTN_CANCEL="[ CANCEL ]"
BTN_YES="[ YES ]"
BTN_NO="[ NO ]"
BTN_CLOSE="[ CLOSE ]"
BTN_SELECT="[ SELECT ]"
BTN_QUIT="[  QUIT  ]"

DLG_DEFFAULT_TITLE="EMC BASE Standalone Installer"
DLG_DEFFAULT_BACKTITLE="EMC BASE Standalone Installer - "
DLG_TITLE="$DLG_DEFFAULT_TITLE"
DLG_BACKTITLE=""

WHIPTAIL_EXIT_STATE=0

# small msgbox for shorter messages
msg_box() {

	local msg_title=$1 msg_text=$2 height=${3:-15} width=${4:-50}
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE message: press [ENTER] to close or [TAB] to select button}"
	local title="$DLG_TITLE"

	[ "$height" = "0" ] && height=15
	[ -z "$msg_title" ] && msg_title="$DLG_TITLE"

	whiptail --title " $msg_title " \
	--backtitle "$backtitle" \
	--ok-button "$BTN_CLOSE" --fb \
	--msgbox "$msg_text" "$height" "$width"
	
	DLG_BACKTITLE=""
	return 0
}

# greater scrollable msg box for long text
text_box() {

	local box_title=$1 box_text=$2 height=${3:-35} width=${4:-150}
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE text box: use up and down key or mouse to scroll text, [TAB] to select buttons}"

	whiptail --title " $DLG_TITLE - $box_title " \
	--backtitle "$backtitle" \
	--ok-button "$BTN_CLOSE" --fb \
	--msgbox --scrolltext "$box_text" "$height" "$width"
	
	DLG_BACKTITLE=""
	return 0
}

# fullscreen scrollable msg box for long text
full_text_box() {

	local box_title="$1" box_text="$2" pct_height=${3:-90} pct_width=${4:-95}
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE text box: use up and down key to scroll text, [TAB] to select buttons}"

	local term_lines=$(tput lines)
	local term_cols=$(tput cols)

	local height=$(( term_lines * $pct_height / 100 ))
	local width=$(( term_cols * $pct_width / 100 ))
	local text_width=$(( width * 95 / 100))

	box_text=$(echo -e "$box_text" | fmt -s -w $(( text_width )))


	whiptail --title " $DLG_TITLE - $box_title " \
	--backtitle "$backtitle" \
	--ok-button "$BTN_OK" --fb \
	--msgbox --scrolltext "$box_text" "$height" "$width"

	DLG_BACKTITLE=""
	return 0
}

# like msg box, returns yes or no
yesno_box() {

	local yesno_title=$1 yesno_text=$2 height=${3:-15} width=${4:-50} selection=0
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE yesno: use [TAB] to select and press [ENTER]}"
	
	[ "$height" = "0" ] && height=15
	[ -z "$yesno_title" ] && yesno_title="$DLG_TITLE"

	whiptail --title " $yesno_title " \
	--backtitle "$backtitle" \
	--yes-button "$BTN_YES" --no-button  "$BTN_NO" --fb \
	--yesno "$yesno_text" "$height" "$width"
	
	selection=$?
	[ $selection -ne $EMC_ok ] && selection=$EMC_no
	DLG_BACKTITLE=""
	return $selection
	
	# this is a way to use an alternative retval
	# mind the blank behind { and the colon ; before }
	[ $selection -eq 0 ]  && { echo "yes"; return 0; }
	
	echo "no"; return $selection
}

# fullscreen yesno_box, returns yes or no
full_confirmation_box() {

	local confirmation_title="$1" confirmation_text="$2" pct_height=${3:-90} pct_width=${4:-95} selection=0
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE confirm: use up and down key to scroll text, [TAB] to select buttons}"

	local term_lines=$(tput lines)
	local term_cols=$(tput cols)

	local height=$(( term_lines * $pct_height / 100 ))
	local width=$(( term_cols * $pct_width / 100 ))
	local text_width=$(( width * 95 / 100))

	confirmation_text=$(echo -e "$confirmation_text" | fmt -s -w $(( text_width )))

	[ -z "$confirmation_title" ] && confirmation_title="$DLG_TITLE"

	whiptail --title " $confirmation_title " \
	--backtitle "$backtitle" \
	--yes-button "$BTN_OK" --no-button  "$BTN_CANCEL" --fb \
	--yesno --scrolltext "$confirmation_text" "$height" "$width"
	
	selection=$?
	[ $selection -ne $EMC_ok ] && selection=$EMC_no
	DLG_BACKTITLE=""
	return $selection
	
	# this is a way to use an alternative retval
	# mind the blank behind { and the colon ; before }
	[ $selection -eq 0 ]  && { echo "yes"; return 0; }
	
	echo "no"; return $selection
}

# like msg box, returns input exit code in global WHIPTAIL_EXIT_STATE
input_box() {

	local input_title=$1 input_text=$2 height=${3:-15} width=${4:-50} input=""
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE input: use [TAB] to select buttons and press [ENTER]}"
	local exit_code=0
	
	[ "$height" = "0" ] && height=15
	[ -z "$input_title" ] && input_title="$DLG_TITLE"

	input=$(whiptail --title " $input_title " \
	--backtitle "$backtitle" \
	--ok-button "$BTN_OK" \
	--cancel-button "$BTN_CANCEL" --fb \
	--inputbox "$input_text" "$height" "$width" 3>&1 1>&2 2>&3)
	
	exit_code=$?
	DLG_BACKTITLE=""
	
	echo "$input"
	return $exit_code
}

# special static output. store $TERM then TERM=ANSI call a procedure 
# and reset TERM after procedure has finished!
info_box() {

	local info_title=$1 info_text=$2 height=${3:-15} width=${4:-50}
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE info box: watch output on bottom statusline. wait until info box is closed}"

	clear

	[ -z "$info_title" ] && info_title="$DLG_TITLE"

	whiptail --title " $info_title " \
	--backtitle "$backtitle" \
	--infobox "$info_text" "$height" "$width"

	#sleep 0.5
}

# fullscreen info box for long text
full_info_box() {

	local info_title=$1 info_text=$2 pct_height=${3:-90} pct_width=${4:-95}
	local backtitle="${DLG_BACKTITLE:-$DLG_DEFFAULT_TITLE info box: watch output on bottom statusline. wait until info box is closed}"

	local term_lines=$(tput lines)
	local term_cols=$(tput cols)

	local height=$(( term_lines * $pct_height / 100 ))
	local width=$(( term_cols * $pct_width / 100 ))
	local text_width=$(( width * 95 / 100))

	info_text=$(echo -e "$info_text" | fmt -s -w $(( text_width )))
	clear

	[ -z "$info_title" ] && info_title="$DLG_TITLE"

	whiptail --title " $info_title " \
	--backtitle "$backtitle" \
	--infobox "$info_text" "$height" "$width"

	#sleep 0.5
}

show_log() {

	local log_title=$1 log_file=$2 pct_height=${3:-90} pct_width=${4:-95}

	local term_lines=$(tput lines)
	local term_cols=$(tput cols)

	local height=$(( term_lines * $pct_height / 100 ))
	local width=$(( term_cols * $pct_width / 100 ))
	local text_width=$(( width * 95 / 100))

	[ -z "$log_title" ] && log_title="$DLG_TITLE"

	whiptail --title " $log_title " \
	--backtitle "$DLG_TITLE: use up and down key to scroll text, [TAB] to select button" \
	--ok-button "$BTN_CLOSE" --fb \
	--textbox --scrolltext "$log_file" "$height" "$width"
}

select_fm() {

	local selection="" title="select FILEMANAGER"

	selection=$(whiptail --title "$DLG_TITLE $title" \
	--backtitle "$DLG_TITLE: use up and down key to scroll list, [SPACE] for selection, [TAB] to select button" \
	--ok-button "$BTN_OK" \
	--cancel-button "$BTN_CANCEL" \
	--radiolist --fb\
	"\nSelect filemanager to INSTALL" 15 55 4 \
	"pcmanfm"   "install for EMC Gtk (suggested)" OFF \
	"spacefm"   "install for EMC Gtk (optional)" OFF \
	"konqueror" "install for EMC KDE (experimental)" OFF \
	"dolphin"   "install for EMC KDE (experimental)" OFF 3>&1 1>&2 2>&3)

	echo "$selection"
}

install_menu(){
	local selection="" exitcode

	selection=$(whiptail --title " $DLG_TITLE Install Menu " \
	--backtitle "$DLG_TITLE: use up and down key to scroll list, [TAB] to select button" \
	--ok-button "$BTN_SELECT" \
	--cancel-button "$BTN_QUIT" --fb \
	--menu "\nselect option:" 24 60 13 \
	"s" "System    report" \
	"g" "get       download speed" \
	"f" "select    Filemanager" \
	"p" "Package   info" \
	"d" "simulate  download" \
	"D"	"DOWNLOAD  EMC packages" \
	"i" "simulate  INSTALL EMC" \
	"I" "INSTALL   EMC" \
	"*" "**************************************" \
	"help"   "   Show help" \
	"quit"   "   Quit Installer" 3>&1 1>&2 2>&3)

	exitcode=$?

	echo "$selection"
	return $exitcode
}

pre_install_menu(){
	local selection="" exitcode

	selection=$(whiptail --title " $DLG_TITLE Pre Install Menu " \
	--backtitle "$DLG_TITLE: use up and down key to scroll list, [TAB] to select button" \
	--ok-button "$BTN_SELECT" \
	--cancel-button "$BTN_QUIT" --fb \
	--menu "\nselect option:" 20 60 10 \
	"s" "   system    report" \
	"G" "   GET       netinst.iso" \
	"W" "   WRITE     iso to usb-stick" \
	"*" "   **************************" \
	"help"          "   Show help" \
	"description"   "   Show description" \
	"readme"        "   Show README" \
	"bash_history"  "   Show template" \
	"quit"          "   Quit Installer" 3>&1 1>&2 2>&3)

#	"r" "   remove    install directory" \

	exitcode=$?

	echo "$selection"
	return $exitcode
}

post_install_menu(){
	local selection="" exitcode

	selection=$(whiptail --title " $DLG_TITLE Post Install Menu " \
	--backtitle "$DLG_TITLE: use up and down key to scroll list, [TAB] to select button" \
	--ok-button "$BTN_SELECT" --nocancel --fb \
	--menu "\nselect option:" 16 60 6 \
	"s" "system    report" \
	"p" "package   info" \
	"*" "**************************************" \
	"help"   "   Show help" \
	"reboot" "   and finish" 3>&1 1>&2 2>&3)

	exitcode=$?

	echo "$selection"
#return $exitcode
	# discards ESC
	return 0
}


main_menu() {
	local selection=""

	if [ $MINIMAL_SYSTEM = "true" ]; then
		selection=$(install_menu)
	elif [ $INSTALL_SUCCESS = "true" ]; then
		selection=$(post_install_menu)
	else
		selection=$(pre_install_menu)
	fi

	[ $? -ne 0 ] && exit 0
	exec_main_menu "$selection"
}
