#!/bin/bash

# Example script for filemanager with custom office directories.
# Please adapt the paths to your local mount points or folders.

# Use the -n option to start a new instance!

# start filemanager
pcmanfm -n \
"menu://applications/" \
"$HOME" \
"$HOME/Downloads" \
"$HOME/.config/polybar" \
"$HOME/Desktop" &
