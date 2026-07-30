#!/bin/bash

get_module_clicks() {
	local app_ini key appkey app

	key="$1"
	app_ini=$(cat "$_USERDIR/applications.ini")

	# Parse applications.ini using pure bash parameter expansion for performance
	while IFS='=' read -r appkey app; do
		appkey=${appkey%% *}

		if [ "$appkey" = "[app-launch]" ]; then break; fi
		if [ "$appkey" = "$key" ]; then 
			# Remove leading whitespace (nested parameter expansion)
			app="${app#${app%%[![:space:]]*}}"
			# Remove trailing whitespace (nested parameter expansion)
			app="${app%${app##*[![:space:]]}}"
			if [ -z "$app" ]; then
				app=" "
			else
				# Remove quotes ONLY if they enclose the ENTIRE string
				if [[ "$app" == \"*\" ]]; then
					app="${app#\"}"
					app="${app%\"}"
				elif [[ "$app" == \'*\' ]]; then
					app="${app#\'}"
					app="${app%\'}"
				fi
 			fi
		app="${app%&}"
		echo "$app"
		break
	fi
	done <<< "$app_ini"
}
