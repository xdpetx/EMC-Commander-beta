#!/bin/bash

# EMC Commander - Application Setup Script
# Strategy: Lean system, no background daemons, resource efficient.
# Target: Debian 13 (Trixie/Bookworm) and similar lean systems.

# Target directory
TARGET_DIR="$HOME/Applications"

# Direct mapping: ["DesktopCategory"]="IconName"
# Folder names are derived from the key, Icons are explicitly assigned
declare -A CATEGORY_MAP=(
	["Graphics"]="applications-graphics"
	["Office"]="applications-office"
	["Internet"]="applications-internet"
	["Multimedia"]="applications-multimedia"
	["Development"]="applications-development"
	["System"]="applications-system"
	["Settings"]="preferences-system"
	["Utilities"]="applications-utilities"
	["Games"]="applications-games"
	["Other"]="applications-other"
)

# Initialize folders and .directory files
setup_directory_icons() {
	echo "EMC Commander: Initializing folders and icons..."

	# Create folders based on map keys and assign the mapped icon
	for dir_name in "${!CATEGORY_MAP[@]}"; do
		local icon_name="${CATEGORY_MAP[$dir_name]}"
		local dir_path="$TARGET_DIR/$dir_name"
		local icon_dir="/usr/share/icons/EMC"

		mkdir -p "$dir_path"

		# Set .directory file for subfolders
		echo "[Desktop Entry]" > "$dir_path/.directory"
		#echo "Icon=$icon_dir/emc-$icon_name.png" >> "$dir_path/.directory"
		echo "Icon=$icon_dir/emc-$icon_name.png" >> "$dir_path/.directory"
	done

	# Set icon for the main directory
	echo "[Desktop Entry]" > "$TARGET_DIR/.directory"
	echo "Icon=applications-all" >> "$TARGET_DIR/.directory"
}

# Function to extract categories and map them to EMC standard folders
get_categories() {
	local raw_categories="$1"
	local cat_list=$(echo "$raw_categories" | tr ';' ' ')
	local found_categories=""

	for cat in $cat_list; do
		case "$cat" in
			Graphics)	found_categories+=" Graphics" ;;
			Office)		found_categories+=" Office" ;;
			Network|WebBrowser) found_categories+=" Internet" ;;
			AudioVideo|Audio|Video|AudioVideoEditing) found_categories+=" Multimedia" ;;
			Development)	found_categories+=" Development" ;;
			System)		found_categories+=" System" ;;
			Settings)	found_categories+=" Settings" ;;
			Utility|Accessories) found_categories+=" Utilities" ;;
			Game)		found_categories+=" Games" ;;
		esac
	done

	if [ -z "$found_categories" ]; then
		found_categories+=" Other"
	fi

	echo "$found_categories"
}

get_applications() {
# Find all .desktop files recursively in system and user paths
# Using -L to follow symlinks if necessary
find /usr/share/applications/ "$HOME/.local/share/applications/" -type f -name "*.desktop" 2>/dev/null | while read -r file; do
	
	# FILTER: Skip hidden entries, links, or entries without a valid executable
	if grep -qEi "^NoDisplay=true|^Type=Link" "$file" || ! grep -q "^Exec=[^$]" "$file"; then
		continue
	fi

	# Extract Category data from the .desktop file
	RAW_DATA=$(grep "^Categories=" "$file" | cut -d'=' -f2)
	SELECTED_CATS=$(get_categories "$RAW_DATA")
	
	# Determine unique filename to prevent collisions in subfolders (like kde4/ or wine/)
	BASE_NAME=$(basename "$file")
	PARENT_FOLDER=$(basename "$(dirname "$file")")
	
	if [[ "$PARENT_FOLDER" != "applications" ]]; then
		FINAL_NAME="${PARENT_FOLDER}_${BASE_NAME}"
	else
		FINAL_NAME="$BASE_NAME"
	fi
	
	# Copy the file to all matching category folders
	for final_cat in $SELECTED_CATS; do
		mkdir -p "$TARGET_DIR/$final_cat"
		cp -L "$file" "$TARGET_DIR/$final_cat/$FINAL_NAME"
	done
done
}

# Start script and ensure target exists
echo -e "setup_applications: Creating application categories for quick access...\n"
mkdir -p "$TARGET_DIR"

setup_directory_icons
get_applications

chmod -R a+x "$TARGET_DIR"

echo -e "Done. Your applications are now ready for quick access in directory $TARGET_DIR.\n"
