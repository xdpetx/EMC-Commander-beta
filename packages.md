# Packages Overview

### Packages needed for the `EMC_standalone_base_installer`.

| Category | Packages |
| :--- | :--- |
| **APT Tools** | `apt-rdepends`, `apt-file`, `apt-show-versions`, `debsecan` |
| **X11 Base** | `xserver-xorg-core`, `xserver-xorg`, `xinit`, `x11-xserver-utils` |
| **Bluetooth** | `bluez`, `pulseaudio-module-bluetooth` |
| **Printing** | `cups`, `cups-client`, `cups-filters`, `avahi-daemon`, `printer-driver-all`, `foomatic-db-compressed-ppds` |
| **System** | `desktop-file-utils`, `xsel`, `psmisc`, `shared-mime-info`, `fontconfig`, `polkitd`, `lxpolkit`, `pkexec`, `plocate`, `network-manager`, `alsa-utils`, `pavucontrol` |
| **EMC Core** | `i3-wm`, `polybar`, `dunst`, `jq`, `lshw`, `maim`, `yad`, `fonts-noto-color-emoji`, `libnotify-bin`, `bc`, `inxi` |
| **File Manager** | `pcmanfm (suggested)` `spacefm (optional)` `dolphin (experimantal)`|

### Installation Progress
To ensure a reliable installation, installation is split into two steps:

| Step | Description |
| :--- | :--- |
| 1. **Download** | All required packages are downloaded first. |
| 2. **Installation** | Once the download is complete, the packages are installed in a single batch. |

view [Download Simulation](logfiles/02_emc_base_installer_download_sim.log.txt) and [Download log](logfiles/03_emc_base_installer_download.log.txt)  
view [Install Simulation](logfiles/04_emc_base_installer_install_sim.log.txt) and [Install log](logfiles/05_emc_base_installer_install.log.txt)  
view System Report [before](logfiles/01_emc_base_installer_syscheck_minimal_system.log.txt) and [after](logfiles/06_emc_base_installer_syscheck_emc_base.log.txt) Installation 
