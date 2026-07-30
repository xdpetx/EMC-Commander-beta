#!/bin/bash

#notify-send "script get_ws_icons.sh started"

# Path configuration based on your environment
WS_CONFIG="$HOME/.config/i3/usr/config_workspaces"
ICONS_INI="$_USERDIR/icons.ini"
TOOLTIPS_INI="$_USERDIR/tooltips.ini"

TEMP_ICONS="/tmp/polybar_icons_ws.tmp"
TEMP_TIPS="/tmp/polybar_tips_ws.tmp"

# Initialize temporary files with section headers
echo "[icons-ws]" > "$TEMP_ICONS"
echo "[tooltip-ws]" > "$TEMP_TIPS"

# Parse workspace config using pure bash parameter expansion for performance
while read -r _ wskey wsname; do
    if [[ $wskey == \$ws* ]]; then
        # Extract numeric index (e.g., 1 from $ws1)
        INDEX=${wskey#\$ws}
        
        # Remove surrounding quotes from workspace name
        tmpval=${wsname%\"}
        clean_name=${tmpval#\"}
        
        # Extract icon (part after the colon) or fallback to index if empty
        ICON_VAL=${clean_name#*:}
        [[ -z "$ICON_VAL" ]] && ICON_VAL="$INDEX"
        
        if [ "$_PBAR_VERSION" -lt 370 ]; then
            # Use bash substring expansion for performance
            SHOW_ICON="${ICON_VAL:0:3}"
        else
        	SHOW_ICON="$ICON_VAL"
        fi
        
        # Append formatted entry to icons temp file
        printf "i_ws_%02d = %s\n" "$INDEX" "$SHOW_ICON" >> "$TEMP_ICONS"
        
        # Append formatted entry to tooltips temp file

        echo "t_ws_$INDEX = open workspace $ICON_VAL" >> "$TEMP_TIPS"
    fi
done < "$WS_CONFIG"

# Update icons.ini by replacing the [icons-ws] section
sed -i '/\[icons-ws\]/,$d' "$ICONS_INI"
cat "$TEMP_ICONS" >> "$ICONS_INI"

# Update tooltips.ini by replacing the [tooltip-ws] section
sed -i '/\[tooltip-ws\]/,$d' "$TOOLTIPS_INI"
cat "$TEMP_TIPS" >> "$TOOLTIPS_INI"

# Clean up temporary files
rm "$TEMP_ICONS" "$TEMP_TIPS"

exit

