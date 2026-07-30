#!/bin/bash

# Example script for filemanager with custom office directories.
# Please adapt the paths to your local mount points or folders.

# Use the -n option to start a new instance!

# start filemanager
pcmanfm -n \
"$HOME/Downloads" \
"/mnt/linuxdata01/DPet.Data_aktuell" \
"/mnt/linuxdata01/DPet.Data_aktuell/Banking" \
"/mnt/linuxdata01/DPet.Data_aktuell/Renda" \
"/mnt/linuxdata01/DPet.Data_aktuell/Rüthen/aktuell" \
"$HOME/Desktop/office" &
