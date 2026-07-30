#!/bin/bash

BUTTON="$1"
MAINBAR_INFO=""

readonly NOTIFY_ID_I=100

# colors from polybar config.ini
readonly color_primary=#F0C674
readonly color_secondary=#8ABEFF
readonly color_foreground=#C5C8C6
readonly color_background=#282A2E

readonly icon_ws="<span background='$color_background' foreground='$color_secondary'> 󰷔 </span>"
readonly icon_win="<span background='$color_background' foreground='$color_secondary'>  </span>"
readonly icon_module="<span background='$color_background' foreground='$color_primary'> 󰈀 </span>"
readonly output_module="<span background='$color_background' foreground='$color_foreground'>ON  </span>"
readonly icon_control="<span background='$color_background' foreground='$color_secondary'>  </span>"
readonly output_control="<span background='$color_background' foreground='$color_foreground'>Des </span>"
readonly mainbar_icon="<span background='$color_background' foreground='$color_primary'></span>"
readonly mainbar_space="<span background='$color_background' foreground='$color_foreground'><u>        </u></span>"

readonly ws_icons="<span background='$color_background' foreground='$color_secondary'> PRO  i3      󰽯    󰋜 </span>"
readonly icons_right="<span background='$color_background' foreground='$color_primary'>   󰍺    󰧺    󰘚  󰋊  󰈀   </span>"
readonly icons_center="<span background='$color_background' foreground='$color_secondary'> 󰮉          󰆾  󱂬  󰷔 </span>"
readonly icons_left="<span background='$color_background' foreground='$color_secondary'> 󰷔   </span>"
readonly icons_mainbar="$icons_left        $icons_center        $icons_right"

INFO_TITLE=" Mainbar Info"
FLAG="/tmp/polybar_mainbar_info.flag"

MAINBAR_INFO="\<b>$mainbar_icon MAINBAR</b> Info <i>(click to close)</i>

 To OPEN an new $icon_ws WORKSPACE use the launchbar:

   scroll  mainbar space $mainbar_space : SHOW launchbar
   scroll  mainbar space $mainbar_space : HIDE launchbar

   left  click $ws_icons on launchbar OPEN this      WORKSPACE
   right click $ws_icons              OPEN alternate WORKSPACE

   click launchbar space for more launchbar info

 To CLOSE a $icon_ws WORKSPACE or $icon_win WINDOW right click the icon or titlebar

 The main bar has 3 sections:

   \t$icons_mainbar

   the right  section shows icons and output from modules   $icon_module$output_module
   the center section is for workspace and window control   $icon_control$output_control
   the left   section shows all opened workspaces and the focused window 

   YELLOW icons  $icon_module: click for APPLICATION launchers
                       scroll  show / hide HELP

   BLUE   icons  $icon_control: click for WORKSPACE or WINDOW control
                       scroll  show / hide HELP

   WHITE  output $output_module: click for STATUS values & detailed INFO

       click left  mainbar space $mainbar_space to show  this info
       click right mainbar space $mainbar_space to close the current info
   dbl click left  mainbar space $mainbar_space open/close configuration toolbar

 To INSTALL APPLICATIONS use [Software] button in the toolbar
"

if [ "$BUTTON" = "left" ]; then
	notify-send -h string:x-dunst-stack-tag:mainbar -r $NOTIFY_ID_I "" "<tt>$MAINBAR_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
fi
