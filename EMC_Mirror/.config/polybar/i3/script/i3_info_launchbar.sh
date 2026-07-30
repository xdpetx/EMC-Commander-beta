#!/bin/bash

BUTTON="$1"
LAUNCHBAR_INFO=""

readonly NOTIFY_ID_I=100

# colors from polybar config.ini
readonly color_primary=#F0C674
readonly color_secondary=#8ABEFF
readonly color_tertiary=#9ABEB7
readonly color_foreground=#C5C8C6
readonly color_background=#282A2E
readonly color_safe=#42A542

readonly launchbar_icon="<span background='$color_background' foreground='$color_primary'>󰅮󰅬</span>"
readonly mainbar_space="<span background='$color_background' foreground='$color_foreground'><u>        </u></span>"

readonly i_file_starter="<span background='$color_background' foreground='$color_tertiary'> 5 󱀾4 3 2 󰈣1  </span>"
readonly i_workspaces="<span background='$color_background' foreground='$color_secondary'> 8 EMC   󰽯  󰋜  </span>"
readonly i_center="<span background='$color_background' foreground='$color_safe'>   󰅮󰅬   </span>"
readonly i_switcher="<span background='$color_background' foreground='$color_safe'>󰅮󰅬</span>"
readonly i_app_starter="<span background='$color_background' foreground='$color_primary'> 󱑿  󱑾  󰏗     󰖟 󰛮  󰍩      󱩽  </span>"

readonly i_tool_l="<span background='$color_background' foreground='$color_foreground'> click left : open workspace 󰋜 </span>"
readonly i_tool_r="<span background='$color_background' foreground='$color_foreground'> click right: open workspace 󰶆 </span>"

LAUNCHBAR_INFO="\<b>$launchbar_icon LAUNCHBAR</b> Info <i>(click to close)</i>

scrolling on mainbar space $mainbar_space  shows or  hides the launchbar.

The launchbar has 3 sections:

	$i_file_starter$i_workspaces $i_center $i_app_starter

    The RIGHT  section is for starting           APPLICATIONS
    The LEFT   section is for opening / focusing WORKSPACES or FILES
    The CENTER section is for switching to       ADDITIONAL LAUNCHBARS

      Left- or right click $i_switcher  to open an additional left or right launchbar
      Left- or right click ICON to launch applications or open workspaces or files

      scroll  on icon: show TOOLTIP $i_tool_r

      click left  launchbar space to show this info
      click right launchbar space to hide any  info
  dbl click left  launchbar space open/close configuration toolbar

  To start applications you can also use the application folder in the filemanager

  For i3 reference  press [win] + F1
  To open appfinder press [win] + d
"

if [ "$BUTTON" = "left" ]; then
	notify-send -h string:x-dunst-stack-tag:mainbar -r $NOTIFY_ID_I "" "<tt>$LAUNCHBAR_INFO</tt>"
elif [ "$BUTTON" = "right" ]; then
	dunstctl close $NOTIFY_ID_I
fi
