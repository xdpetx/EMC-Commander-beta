#!/bin/bash

# wrapper script for a fixed format applications.ini

#notify-send "i3_open_file started"

FILE_KEY="$1"
CONFIG_FILE="$_USERDIR/applications.ini"
CONFIG_CONTENT=$(cat "$CONFIG_FILE")

readonly NOTIFY_ID=1003
readonly NOTIFY_TIME=2500

while IFS='=' read -r key value; do
	# Direct comparison, then clean the quotes from the value
	if [[ "$key" == "$FILE_KEY " ]] || [[ "$key" == "$FILE_KEY" ]]; then
		temp_val=$(echo $value)
		#remove quotation marks
		file_val="${temp_val#\"}"
		FILE_VALUE="${file_val%\"}"

		if [[ "$FILE_VALUE" == "" ]]; then
			notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ EMC Warning" "\n$key= : no file to open defined in applications.ini"
			exit 0
		fi

		# 1. Replace $HOME or ${HOME} with the actual path.
		FILE_VALUE="${FILE_VALUE/\$HOME/$HOME}"
		FILE_VALUE="${FILE_VALUE/\$\{HOME\}/$HOME}"

		# 2. Replace the tilde ~ at the beginning with the HOME path.
		if [[ "$FILE_VALUE" == "~/"* ]]; then
			FILE_VALUE="${HOME}${FILE_VALUE:1}"
		fi

		if [ ! -f "$FILE_VALUE" ]; then
			notify-send -r $NOTIFY_ID -t $NOTIFY_TIME "⚠️ EMC Warning" "\n$key= $FILE_VALUE: file doesn't exist"
			exit 0			
		fi

		xdg-open "$FILE_VALUE" &
		break
	fi
done <<< "$CONFIG_CONTENT"
