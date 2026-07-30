#!/bin/bash

# EMC_standalone_base_installer - dialog textes:
#
#	INSTALL_HELP, PRE_INSTALL_HELP, POST_INSTALL_HELP
#	DESCRIPTION_TXT, MSG_EMC_RUNNING, MSG_NOT_CONNECTED, 
#	MSG_NO_DOWNLOAD, DOWNLOAD_NOTE, INST_NOTE
#
#	sys_header, finish_setup_simulation
#	apt_install_filter, apt_install_summary_filter, 
#
# DEBIAN VERSION

INSTALL_HELP="
Install menu options:

   s             System    report          check your system before install 
   g             get       download speed  view download speed
   f             select    filemanager     pcmanfm or spacefm 
   p             Package   info            view packages needed, install state
   d             download  simulation      shows download size, install size and estimated time
   D             DOWNLOAD  packages        run download
   i             install   simulation      simulate install, view log and then install
   I             INSTALL   EMC             install after running simulation
   *             *************************
   help          Show help
   description   Show description
   quit          Quit Installer

Note: After installed successfully the menu switches to Post install menu.
"

PRE_INSTALL_HELP="
Pre install menu options:

   s             System    report      check your system
   G             GET       image       get and verify debian netinst image
   W             WRITE     image       write image to usb-stick
   *             *********************
   help          Show help             show pre install help
   description   Show description      show EMC description
   readme        Show README           show README file
   bash_history  Show template         show bash_history_template
   quit          Quit Installer

Note: This script will create an install directory in \"$HOME/EMC_install\"
      After installing EMC successfully this directory can be removed .

      debian-xx.x.x-amd64-netinst.iso will be downloaded to $DOWNLOAD_DIR

#################################################################################################

When installing Debian minimal system on step 2

   - use Install not Graphical install to avoid tiny fonts
   - choose manual partition when you are asked for
   - REMOVE presets and ACTIVATE ONLY standard system utilities on software selection:

   [ ] Debian Desktop Environment     and
   [ ] ... GNOME                      and select only
   ...
   [*] standard system utilities      NOTHING ELSE!!!

   If you are not sure how to install a Debian minimal system download guidance from github

After installing the minimal system:

   1. Copy EMC_INSTALL_standalone.tar.gz to ~/Downloads
   2. Edit bash_history_template and copy it as .bash_history to ~

If installed on the same device, use your filemanager to mount and copy.
Otherwise, use a second USB stick as described in the bash_history_template.
"
#      After installing EMC successfully use the r option to remove.
#   r             remove    install dir remove install directory (NOT implemented)

POST_INSTALL_HELP="
Post install menu options:

   s        System    report      check your system after install 
   p        Package   info        view packages needed, install state
   *        ****************
   help     Show help
   reboot   reboot system

Note: Aborting with [ESC] is disabled. You must reboot to finalize!

#########################################################################

EMC Commander start instructions:

   1. After reboot, boot the partition where EMC Commander is installed.
   2. After login, start EMC Commander with: startx
   3. When EMC has started you will see a Mainbar info notify for first instructions.
   4. To install software open EMC Configuration Toolbar how described in Mainbar info

   When EMC Commander is running well, boot back into your install partition, 
   and remove the \$HOME/EMC_install directory.
"

DESCRIPTION_TXT="EMC (Early Morning Commander) standalone desktop is a lightweight alternative to conventional desktop environments
based on a collection of configuration files and scripts for controlling i3 and polybar.

Unlike standard i3, EMC is mouse-controlled like a conventional desktop environment, 
while maintaining i3's keyboard efficiency.
EMC thus combines the convenience of a traditional desktop with the performance of a tiling window manager.

Supported monitor resolutions (optimized for 27\"): 2560x1440, 1920x1080, 1680x1050, 1600x900, 1440x900 and 1280x1024.

These resolutions should work well on 24\" monitors.
Other monitor sizes or resolutions may require manual adjustments to font sizes and gaps.

The installer will set up the EMC standalone desktop on a minimal Debian system.  
Before install you must download a Debian netinst iso file and install a Debian minimal system.  
Use the installer to get this iso and write it to a usb stick.  
  
NOTE: Uninstalling EMC is not supported. To revert, reinstall Linux and select your preferred desktop environment.  
  
Installation consists of four steps:  
  
Step 1 (Preinstall)    : Download the Debian netinstall ISO and write it to a USB stick.
Step 2 (Install Debian): Install Debian minimal system from USB stick.  
Step 3 (Install EMC)   : Download EMC packages and perform the installation.  
Step 4 (Postinstall)   : View installation results and reboot.  
  
Steps 1, 3 and 4  have own menu and help sections. Use 'help' for more information!

When installing Debian on step 2

   - use Install not Graphical install to avoid tiny fonts
   - choose manual partition when you are asked for
   - REMOVE presets and ACTIVATE ONLY standard system utilities on software selection!

   If you are not sure how to install a Debian minimal system download guidance from github
"

MSG_EMC_RUNNING="Cannot download or install while EMC is running

To download or install EMC leave EMC Session and run EMC_base_installer.sh from a minimal system"

MSG_NOT_CONNECTED="Cannot install or simulate install without internet

Check your internet connection before install or simulate install!"

MSG_NO_DOWNLOAD="Cannot install or simulate install without packages

Download packages before install or simulate install!"

MSG_REMOVE_DEV="

Insert ONLY ONE! usb flash drive.

Remove the other devices that are not to be used.
"

MSG_WRITE_ISO="            ATTENTION!

All data on this USB drive will be lost. Continue?
"

INST_NOTE="   
   Note: This is a real INSTALLATION!

         Install will take a while, Some packages are large 
         and require additional time to configure. So be patient ...

"

sys_header(){

cat <<EOF


System:

   OS               : $OS ($OS_LIKE)
   Desktop          : $DESKTOP_ENV
   Desktop sessions : $AVAILABLE_DESKTOP_SESSIONS
   Standalone EMC   : $STANDALONE_SYSTEM
   Desktop    EMC   : $DESKTOP_SYSTEM
   Minimal system   : $MINIMAL_SYSTEM
   EMC installed    : $EMC_installed
   EMC running      : $EMC_running\n
EOF
}

download_note(){

local time=$1 duration

duration=$(date -u -d "@$time" +"%Mm %Ss")

cat <<EOF
  
   Note: Download packages now, no simulation!

         Package download maybe quite slow depending on your connection:

          DSL  6.000   0.75 MB/s   about 9 minutes
          DSL 16.000   2.0  MB/s   about 3 minutes
         VDSL 50.000   6.0  MB/s   about 1 minute

         Download size  : $DOWNLOAD_SIZE MB
         your connection: $DOWNLOAD_SPEED MB/s estimated duration: $duration
 
         During download no output will be generated on screen. You see only a counter in statusline. 
         Maybe it will take 1 or 2 minutes longer than estimated. So be patient if your connection is slow ...
\n
EOF
}


msg_download_speed(){

cat <<EOF
Download speed ca. $DOWNLOAD_SPEED MB/s

    DSL  6.000  =  0.75 MB/s
    DSL 16.000  =  2.0  MB/s
   VDSL 50.000  =  6.0  MB/s
EOF
}

msg_download_sucess(){

cat <<EOF

   Debian netinst iso downloaded and verified
   You can write to usb stick now.
EOF
}

msg_write_usb(){

local duration=$1

cat <<EOF

   Estimated duration: $duration sec.
   
   Maybe it will take a little bit longer
   than estimated. This estimation is not 
   very reliable
   
   So be patient ...
EOF
}

finish_setup_simulation(){

cat <<EOF
   will run mkdir -p \$HOME/Desktop
   will run mkdir -p \$HOME/Pictures
   will run mkdir -p \$HOME/.config/polybar/log

   will setup extended sources for apt ...
   
   will initialize plocate search database: updatedb

   will enable network interface ...

   will setup your user groups: usermod -aG cdrom,floppy,sudo,audio,dip,video,plugdev,users,netdev,bluetooth,lp,lpadmin,dialout,input

   will create .xinitrc for startx: exec i3

EOF
}

gtk_settings() {
cat << EOF
[Settings]
gtk-icon-theme-name = hicolor

gtk-enable-animations = 0
gtk-dialogs-use-header = 0

EOF
}

apt_install_filter() {
cat << EOF
Get:
Reading database
Preparing to unpack
Unpacking
Selecting previously unselected
Setting up
Processing triggers
EOF
}

apt_install_summary_filter() {
cat << EOF
### install_standalone_packages
Preconfiguring packages ...
No schema files found:
Adding 'diversion of
Removing 'diversion of
update-alternatives:
Created symlink 
No diversion 
Updating PPD files
colord.service is
EOF
}
