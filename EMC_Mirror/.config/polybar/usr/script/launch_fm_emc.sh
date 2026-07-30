#!/bin/bash

# Example script for filemanager with custom office directories.
# Please adapt the paths to your local mount points or folders.

# Use the -n option to start a new instance!

# start filemanager
pcmanfm -n \
"$HOME" \
"$HOME/Pictures" \
"$HOME/.config/polybar" \
"$HOME/.config/polybar/usr" \
"$HOME/.config/i3" \
"$HOME/.config/i3/usr"
