#!/bin/bash

# Dialog  Text for EMC_standalone_app_installer

# DEBIAN VERSION

# Format:	"Selection"	"Package"		"Keyword"		"Suggestion"	"Status"	"ENV"	"Description"	"Comment"
#			"TRUE"		"lxterminal"	"Terminal"		"Required"		"INSTALLED"	"gtk"	"not available"	"Base app"

SEPARATOR_BASE=(	"" "" "" "### BASE APPS ###" "" "" "" "")

EMC_BASE_APPS=(
	"TRUE"  "lxterminal"          "Terminal"            "Required"  "" "gtk" "LXDE terminal emulator" ""
	"TRUE"  "mousepad"            "Editor"              "Required"  "" "gtk" "simple Xfce oriented text editor" ""
	"TRUE"  "firefox-esr"         "Browser"             "Required"  "" "gtk" "Mozilla Firefox web browser - Extended Support Release (ESR)" ""
	"FALSE" "xarchiver"           "Archiver"            "Base"      "" "gtk" "GTK+ frontend for most used compression formats" ""
	"FALSE" "catfish"             "Search tool"         "Base"      "" "gtk" "File searching tool which is configurable via the command line" ""
	"FALSE" "xfce4-appfinder"     "Search Apps"         "Base"      "" "gtk" "Application finder for the Xfce4 desktop environment" ""
	"FALSE" "xfce4-taskmanager"   "Taskmanager"         "Base"      "" "gtk" "process manager for the Xfce4 Desktop Environment" ""
	"FALSE" "uget"                "Downlaod Tool"       "Base"      "" "gtk" "easy-to-use download manager written in GTK+" ""
	"FALSE" "baobab"              "Disk Usage Analyzer" "Base"      "" "gtk" "GNOME disk usage analyzer" "*** ONLY CORE INSTALL !!! ***"
	"FALSE" "gnome-disk-utility"  "Drive Management"    "Base"      "" "gtk" "manage and configure disk drives and media" ""
	"FALSE" "galculator"          "Calculator"          "Base"      "" "gtk" "scientific calculator" ""
)

SEPARATOR_OFFICE=(	"" "" "" "### OFFICE ###" "" "" "" "")

EMC_OFFICE=(
	"FALSE" "libreoffice-writer"  "Word processing"     "Optional" "" "gtk" "office productivity suite -- word processor" ""
	"FALSE" "libreoffice-calc"    "Spreadsheet"         "Optional" "" "gtk" "office productivity suite -- spreadsheet" ""
	"FALSE" "evince"              "Document viewer"     "Yes"      "" "gtk" "Document (PostScript, PDF) viewer" ""
	"FALSE" "qpdfview"            "Document viewer"     "Optional" "" "Qt"  "tabbed document viewer" "install only if you want to install other qt apps"
	"FALSE" "zathura"             "Document viewer"     "Optional" "" "gtk" "document viewer with a minimalistic interface" ""
	"FALSE" "orage"               "Calendar"            "Optional" "" "gtk" "Calendar for Xfce Desktop Environment" ""
	"FALSE" "osmo"                "Organizer"           "no"       "" "gtk" "personal organizer for GTK+" ""
	"FALSE" "gnome-calendar"      "Calendar"            "no"       "" "gtk" "Calendar application for GNOME" "use google calendar in browser"
)

SEPARATOR_NET=(	"" "" "" "### INTERNET ###" "" "" "" "")

EMC_NET=(
	"FALSE" "chromium"            "Web Browser"          "Optional" "" "gtk" "web browser" ""
	"FALSE" "thunderbird"         "email client"         "Optional" "" "gtk" "mail/news client with RSS, chat and integrated spam filter" ""
	"FALSE" "hexchat"             "chat client"          "Optional" "" "gtk" "IRC client for X based on X-Chat 2" ""
)

SEPARATOR_GRAPHICS=(	"" "" "" "### GRAPHICS ###" "" "" "" "")

EMC_GRAPHICS=(
	"FALSE" "gimp"                "Image Editor"        "Optional" "" "gtk" "GNU Image Manipulation Program" ""
	"FALSE" "libreoffice-draw"    "Graphics"            "Optional" "" "gtk" "office productivity suite -- drawing" ""
)

SEPARATOR_GUI_TOOLS=(	"" "" "" "### GUI TOOLS ###" "" "" "" "")

GUI_TOOLS=(
	"FALSE" "geany"               "Editor"              "Yes"      "" "gtk" "fast and lightweight IDE" ""
	"FALSE" "featherpad"          "Editor"              "Optional" "" "Qt"  "lightweight plain-text editor written in Qt" "install only if you want to install other qt apps"
	"FALSE" "ristretto"           "Picture viewer"      "Yes"      "" "gtk" "lightweight picture-viewer for the Xfce desktop environment" ""
	"FALSE" "thunar"              "Filemanager"         "Yes"      "" "gtk" "File Manager for Xfce" "Secondary fm"
	"FALSE" "gparted"             "Partition Editor"    "Optional" "" "gtk" "GNOME partition editor" ""
	"FALSE" "simple-scan"         "scan utility"        "Optional" "" "gtk" "Simple Scanning Utility" ""
	"FALSE" "pdfarranger"         "Pdf Arrangement"     "Yes"      "" "gtk" "merge, split and re-arrange pages from PDF documents" ""
	"FALSE" "cpu-x"               "system profiling"    "Optional" "" "gtk" "Tool that gathers information on CPU, motherboard and more" "use CPU Info instead"
)

SEPARATOR_CLI_TOOLS=(	"" "" "" "### CLI TOOLS ###" "" "" "" "")

CLI_TOOLS=(
	"FALSE" "info"                "GNU info"             "Optional" "" "cli" "Standalone GNU Info documentation browser" ""
	"FALSE" "htop"                "Process Monitor"      "Yes"      "" "cli" "interactive processes viewer" ""
	"FALSE" "ncdu"                "Disk Usage"           "Optional" "" "cli" "ncurses disk usage viewer" ""
	"FALSE" "ripgrep"             "Fast Search"          "Optional" "" "cli" "Recursively searches directories for a regex pattern" ""
	"FALSE" "fzf"                 "Fuzzy Finder"         "Optional" "" "cli" "general-purpose command-line fuzzy finder" ""
	"FALSE" "imagemagick-7.q16"   "image manipulation"   "Optional" "" "cli" "image manipulation programs -- quantum depth Q16" "*** ONLY CORE INSTALL !!! ***"
	"FALSE" "rsync"               "File Sync"            "Yes"      "" "cli" "fast, versatile, remote (and local) file-copying tool" ""
	"FALSE" "curl"                "URL data transfer"    "Yes"      "" "cli" "command line tool for transferring data with URL syntax" ""
	"FALSE" "iproute2"            "networking tools"     "Yes"      "" "cli" "networking and traffic control tools" ""
	"FALSE" "sshfs"               "Host Data Share"      "Optional" "" "cli" "filesystem client based on SSH File Transfer Protocol" "enables automated data exchange with host"
	"FALSE" "zip"                 "Aarchiver"            "Yes"      "" "cli" "Aarchiver for .zip files" ""
	"FALSE" "unzip"               "De-archiver"          "Yes"      "" "cli" "De-archiver for .zip files" ""
	"FALSE" "adb"                 "Android Debug Bridge" "Optional" "" "cli" "Android Debug Bridge" ""
)

SEPARATOR_CONFIG=(	"" "" "" "### CONFIG ###" "" "" "" "")

EMC_CONFIG=(
	"FALSE" "system-config-printer" "Configure printers"    "Optional" "" "gtk" "graphical interface to configure the printing system" "not really needed, use cups"
	"FALSE" "sane-utils"            "Scanner Config"        "Optional" "" "cli" "API library for scanners -- utilities" "use with scanimage"
	"FALSE" "sane-airscan"          "Modern Scanner Driver" "Optional" "" "cli" "SANE backend for AirScan (eSCL) and WSD document scanner" "best for modern devices"
	"FALSE" "simple-scan"           "Scanner GUI"           "Optional" "" "gtk" "Simple Scanning Utility" "install if you need a GUI"
	"FALSE" "ipp-usb"               "Scanner Driver"        "Optional" "" "cli" "Daemon for IPP over USB printer support" "install for USB support"
	"FALSE" "nm-connection-editor"  "Configure network"     "Optional" "" "gtk" "network management framework (connection config editor)" ""
	"FALSE" "blueman"               "Bluetooth Manager"     "Optional" "" "gtk" "Graphical bluetooth manager" ""
	"FALSE" "synaptic"              "Packet Manager"        "Optional" "" "gtk" "Graphical package manager" "use app installer instead"
)

SEPARATOR_DEVEL=(	"" "" "" "### DEVELOPMENT ###" "" "" "" "")

EMC_DEVEL=(
	"FALSE" "linux-headers-amd64"            "Linux Headers" "Optional"      "" "cli" "Header files for Linux amd64 configuration (meta-package)" ""
	"FALSE" "build-essential"                "Build tool"    "Optional"      "" "cli" "Informational list of build-essential packages" ""
	"FALSE" "virtualbox"                     "Emulator"      "Optional"      "" "Qt"  "x86 virtualization solution - base binaries" "NOTE: Needs linux-headers and build-essential. CORE INSTALL suggested !"
	"FALSE" "virtualbox-guest-additions-iso" "vbox addon"    "Optional"      "" ""    "guest additions iso image for VirtualBox" ""
	"FALSE" "qemu-system-x86"                "Emulator"      "Optional"      "" "gtk" "QEMU full system emulation binaries (x86)" ""
	"FALSE" "virt-manager"                   "Emulator GUI"  "Optional"      "" "gtk" "desktop application for managing virtual machines" ""
	"FALSE" "dosbox"                         "Dos Emulator"  "Optional"      "" "gtk" "x86 emulator with ... VGA/SVGA graphics, sound and DOS" ""
)

#LC_ALL=C apt-cache show $pkg | grep '^Description-en:'

txt_syslog(){

cat <<EOF
### SYSTEM REPORT $now ###

1. SYSTEM

   Internet connected: $INET_CONNECTED

   OS                : $OS ($OS_FAMILY)
   Desktop           : $DESKTOP_ENV
   Desktop sessions  : $AVAILABLE_DESKTOP_SESSIONS
   Standalone EMC    : $STANDALONE_SYSTEM

   System Locale     : $SYSTEM_LOCALE

   i3      found - $i3_install_VERSION
   polybar found - $polybar_install_VERSION

2. DISK SPACE

$disk_space

3. INSTALLED PACKAGES: $pkg_installed

4. MEMORY USAGE

$mem_free

5. ACTIVE PROCESSES 

$proc_state

6. APT CACHE TIME

$apt_cache_time

7. GUI LIBRARIES (BLOAT CHECK)

GTK:

${gtk_lib:-none}

QT:

${qt_lib:-none}

KDE:

${kde_lib:-none}
EOF
}

txt_bad_cache(){

cat <<EOF

 <b>Cannot run EMC app installer with bad apt cache (duration: $duration ms).
 Do you want to repair apt cache now?

 This takes a few seconds.</b>
EOF
}

filter_dirty(){

cat <<EOF
libqt
libkf6
libwebkit
libadwaita
libgtkmm
libatkmm
libpangomm
libcairomm
libsigc++
xdg-desktop-portal-gtk
xdg-dbus-proxy
evolution-data-server
pocketsphinx
gstreamer
libavcodec
libavformat
docbook
yelp
geoclue
libcanberra
fonts-kacst
fonts-lao
fonts-lklug-sinhala
fonts-noto-cjk
fonts-noto-color-emoji
fonts-sil-abyssinica
fonts-sil-padauk
fonts-tibetan-machine
EOF
}

dirty_info="

Additional system components are required for full functionality of the
package, but may slow down and blow up the system. 

Without these components the program runs in a limited core configuration,
which is often sufficient. 

With these components the program offers its full range of features, 
e.g. a graphical interface, though potentially including entirely superfluous
functions, but requires more system resources. 

A good example is baobab: a full installation requires 241 MB, whereas the
core installation requires only 7130 kB and functions perfectly well. 

pcmanfm in contrast will not run properly with a core installation, 
important functions—such as mounting drives and USB sticks—are missing.
"
