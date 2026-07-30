#!/bin/bash

# script to create EMC_INSTALL_standalone.tar.gz

# Set up versioning and folder structure
INSTALL_CONFIG="$HOME/EMC_Mirror/.config"
INSTALL_BASE_INSTALLER="$HOME/EMC_Mirror/base_installer"
INSTALL_BASE="/tmp/emc_backup"
INSTALL_DEST="$INSTALL_BASE/EMC_install"

EMC_INSTALL_DIR="$HOME/EMC_Mirror"
CONFIG_ARCHIVE="$EMC_INSTALL_DIR/EMC_CONFIG.tar.gz"
INSTALL_ARCHIVE="$EMC_INSTALL_DIR/EMC_INSTALL_standalone.tar.gz"

create_install_archive="true"

echo -e "EMC_install_archive_builder -creating install archive ...\n"

# Create backup dirs
mkdir -p "$INSTALL_DEST"
mkdir -p "$EMC_INSTALL_DIR"

echo "Step 1: Packing configurations..."

cp -r "$INSTALL_CONFIG/" "$INSTALL_DEST/"

#cd "$INSTALL_DEST"
#tar -czf "$CONFIG_ARCHIVE" *
#cd "/tmp"
tar -czf "$CONFIG_ARCHIVE" -C "$INSTALL_DEST" .
rm -rf "$INSTALL_DEST"

echo "Step 2: Including installation scripts and howto..."
mkdir -p "$INSTALL_DEST"
cp -r "$INSTALL_BASE_INSTALLER/"* "$INSTALL_DEST/"

	# move config to INSTALL_DEST/EMC_install
	mv "$CONFIG_ARCHIVE" "$INSTALL_DEST/"

	echo "Step 3: Creating Install-Archive..."
	cd "$INSTALL_BASE"
	tar -czf "$INSTALL_ARCHIVE" *
	cd "/tmp"

rm -rf "$INSTALL_BASE"

echo -e "\nArchive stored in $EMC_INSTALL_DIR"
