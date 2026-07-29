<H1>EMC configuration files</H1>
  
**applications.ini** is divided into five sections:

<details>
<summary>Mainbar Settings</summary>
<br>
  
```
# Mainbar Module Configuration
[app-main]

# load your modules
# comment / uncommennt for use

# full module list for i3 1600 x 900 and more
main_modules_right = screenshot display pulseaudio keyboard cpu memory filesys eth wlan date i3_exit

# reduced module list
#main_modules_right = display keyboard date i3_exit

# Module Click Actions
# Define commands for left, right, and double clicks
# Leave blank if you won't start any app with this click

# module cpu
cpu_left = xfce4-taskmanager &
cpu_right =
cpu_dbl_left = cpu-x &
cpu_dbl_right =

...
```
    
</details>

<details>
<summary>Data Settings</summary>
<br>
  
```
# Section to access some EMC data
[app-data]

# get value with echo $LANG in terminal
locale = de_DE.UTF-8

# mount point for filesys module
#filesys_mount = /media/user_name/your_device
#filesys_mount = /home
filesys_mount = /

# minimum = 3! Don't change, this is good
i3_workspaces_width = 3
# yes for show
show_mainbar_info_on_start = yes
# width for window module
i3_windows_width = 15
i3_win_width = 3

```
    
</details>

<details>
<summary>Launchbar Settings</summary>
<br>Setup your launchbars:
<br>
  
```
# Launchbar and Starter Configuration
[app-launch]

# configure your launchbars with starters
launchbar_left_modules_left = audio02 audio01 video01 video02 pic01
launchbar_left_modules_right = dosbox01

launchbar_center_modules_right = fm01 fm02 package02 user_space01 web01 mail01 download01 messenger01 user_space01 terminal01 editor01 search01 user_space01

launchbar_right_modules_left = hw01 printer01 bluetooth01 net01
launchbar_right_modules_right = calendar01 calculator01 office01 pdftool01 scan01

# space
#starter: user_space01 user_space02 user_space03
user_space01_padding = 1
user_space02_padding = 25
user_space03_padding = 50
```

Setup your starters:

```
# categories like xfce4 appfinder but no duplicate keys
# see also /usr/share/applications

# Launchbar Click Actions
# Define starter commands for left and right single click
# Leave blank if you won't start any app with this click

# AudioVideo
#starter: audio01 audio02 audio03-
audio01_left = spotify &
audio01_right =
audio02_left = audacity &
audio02_right =
audio03_left =
audio03_right =
#starter: video01 video02 video03-
video01_left = mpv &
video01_right = vlc &
video02_left = obs-studio &
video02_right =
video03_left =
video03_right =

# DesktopSettings
#starter: settings01 bluetooth01 net01 printer01
settings01_left =
settings01_right =
bluetooth01_left = blueman-manager &
bluetooth01_right = pavucontrol &
net01_left = nm-connection-editor &
net01_right =
printer01_left = xdg-open http://localhost:631 &
printer01_right =

...
```

your 5 user starters you can setup here:

```
# Special User Apps
#starter: user01 user02 user03 user04 user05

# NOTE: Use simple commands here (e.g., /path/to/app --option).
# DO NOT use pipes (|) or logical operators (&&, ||). 
# For complex commands, point to a .sh file instead.

# However, complex paths or options are processed properly. Examples:
# user01_left = /usr/lib/virtualbox/VirtualBoxVM --comment WindowsXP_Music --startvm {e7d074d8-6d4f-43a9-a9bc-2e8c01f42345}
# user01_left = VBoxManage startvm WindowsXP_Music --type sdl
# user01_left = VBoxSDL -startvm WindowsXP_Music
# user01_right = /usr/lib/virtualbox/VirtualBoxVM --comment Ubuntu_10.04 --startvm {b64a6ef0-a1a9-4fe2-83ca-046a80d8847e}
# user01_right = VBoxManage startvm Ubuntu_10.04 --type sdl
# user01_right = VBoxSDL -startvm Ubuntu_10.04
# user02_left = /mnt/linuxdata01/genymotion/player --vm-name "Google Pixel 2"

user01_left =
user01_right =
...
```
    
</details>

<details>
<summary>Startscript Settings</summary>
<br>
  
To execute a program or script on opening a new workspace you must edit the [ws-script] section in app.ini:

```
[ws-script]
# Execute script or app on workspace start
# you can use $_USERSCRIPT to acces your scripts in $HOME/.config/polybar/i3/usr/script
# leave blank if no start script is required.
s_ws1 = $_USERSCRIPT/launch_fm_home.sh
...

In $_USERSCRIPT are some start scripts which can be executed when you open a workspace first.
```

</details>

<details>
<summary>File Settings</summary>
<br>
  
For quick file access in the launchbar edit this:
  
```
[user-files]
# Quick file access
# Note: Paths can use $HOME, ${HOME} or ~/ to refer to your home directory.
# Other environment variables are NOT supported in this config.
# Use absolute path instead

file01 =
file01_alt =
file02 =
file02_alt =
file03 =
file03_alt =
file04 = $HOME/.config/i3/usr/config_workspaces
file04_alt = $HOME/.config/i3/usr/config_usercommands
file05 = $HOME/.bash_history
file05_alt = $HOME/.config/i3/usr/i3_Reference_Card.pdf
```
  
</details>

**tooltips.ini** is divided into three sections:

<details>
<summary>Tooltip Starter Settings</summary>
<br>Setup starter tooltips for your launchbars:
<br>
  
```
# tooltips for your launchbar, edit for your needs
#STANDALONE EMC Version

#You can copy the entries from applications.ini, but you must prefix them with a t_.!!!
#If you leave it blank, the tooltip “click-right: not implemented” will appear.

[tooltip-launch]
# categories like xfce4 appfinder but no duplicate keys
# see also /usr/share/applications

#AudioVideo
t_audio01_left = spotify
t_audio01_right =
t_audio02_left = audacity
t_audio02_right =
t_audio03_left =
t_audio03_right =

t_video01_left = mpv
t_video01_right = vlc
t_video02_left = obs-studio
t_video02_right =
t_video03_left =
t_video03_right =
...
```

</details>

<details>
<summary>File Tooltip Settings</summary>
<br>
  
Setup tooltips for quick file access:
  
```
[tooltip-files]
# file opener in center launchbar
t_file01 =
t_file01_alt =
t_file02 =
t_file02_alt =
t_file03 =
t_file03_alt =
t_file04 = edit config_workspaces
t_file04_alt = edit config_usercommands
t_file05 = edit bash history
t_file05_alt = show i3 keybinding reference

```
  
</details>
  
<details>
<summary>Workspace Tooltip Settings</summary>
<br>
  
Do not change these settings!
  
```
#do not change this, generated by script
[tooltip-ws]
t_ws_1 = open workspace 󰋜
t_ws_2 = open workspace 󰽯
t_ws_3 = open workspace 󰽯 2
t_ws_4 = open workspace 
t_ws_5 = open workspace  2
t_ws_6 = open workspace EMC
t_ws_7 = open workspace PROGRAMMING
t_ws_8 = open workspace 8
t_ws_9 = open workspace 9
t_ws_10 = open workspace 󰶆

```
  
</details>

**icons.ini** is divided into sections too:

<details>
<summary>Starter icons</summary>
<br>Setup starter icons for your launchbars:
<br>
  
```
# icons.ini edit for your needs

# Icons for your launchbars. Note: icons may still cause warnings 
# if your Nerd Font version doesn't support it.

# for more icons look here: https://www.nerdfonts.com/cheat-sheet

# every icon can trigger a click-left or a click-right event
# so that you can start 2 applications per icon

# same starters as in applications.ini but prefixed with i_

# categories like xfce4 appfinder
# see also /usr/share/applications

[icons-launch]

#AudioVideo
i_audio01 = 󱀞
i_audio02 = 󰲸
i_audio03 = 
i_video01 = 󰕧
i_video02 = 󰯜
i_video03 = 󰃽

# DesktopSettings
i_settings01 = 
i_bluetooth01 = 
i_net01 = 󰩠
i_printer01 = 󰐪

(Nerd Fonts are not displayed correctly on GitHub)
```
  
</details>
  
<details>
<summary>File starter icons</summary>
  
<br>Setup file starter icons:
  
  
```
[icons-files]
# files
i_file01 = 󰈣1
i_file02 = 2
i_file03 = 3
i_file04 = 󱀾4
i_file05 = 5

(Nerd Fonts are not displayed correctly on GitHub)
```
  
</details>

**monitor.ini** is used by Polybar to adjust mainbar and launchbar settings:

<details>
<summary>monitor.ini</summary>
<br>
  
```
[monitor-data]

# KOORUI E2721F 27" 

# 1920x1080
launchbar_center_width = 33%
launchbar_center_offset_x = 32.7%

# shows all launchbars in center position
launchbar_left_offset_x = 42.2%
launchbar_right_offset_x = 42.2%

# change for left and right launchbar
launchbar_width = 16%
# change for all launchbars
launchbar_offset_y = 93.6%

mainbar_height = 24pt
launchbar_height = 18pt

# change only size and offset!
# size=<yoursize;youroffset
mainbar_font_0 = Symbols Nerd Font Mono:style=Regular:size=12.5;2
mainbar_font_1 = Noto Sans:size=12.5;2

launchbar_font_0 = Symbols Nerd Font Mono:style=Regular:size=11;2
launchbar_font_1 = Noto Sans:size=11;2
```
  
</details>


**config_workspaces** specifies the workspace icons:

<details>
<summary>Workspace icons</summary>
<br>Setup Workspace icons:
<br>
  
```
# Define names for default workspaces for which we configure key bindings later on.
# We use variables to avoid repeating the names in multiple places.

# --- EDITING RULES ---
# Format is  set $ws1 "WS_NUMBER:WS_NAME"
# ONLY edit the text inside the quotes AFTER the colon.
# Example: set $ws1 "1:YOUR_ICON_HERE"
#
# DO NOT change 'set'
# DO NOT change '$wsX'
# DO NOT remove or comment out any lines!
# DO NOT add lines!
# WS_NAME may not be empty or whitespace
# Any other change will break the Polybar icons and the startup scripts.

### config_workspaces BEGIN ###
set $ws1 "1:󰋜"
set $ws2 "2:󰽯"
set $ws3 "3:󰽯 2"
set $ws4 "4:"
set $ws5 "5: 2"
set $ws6 "6:EMC"
set $ws7 "7:PROGRAMMING"
set $ws8 "8:8"
set $ws9 "9:9"
set $ws10 "10:󰶆"
### config_workspaces END  ###

(Nerd Fonts are not displayed correctly on GitHub)
```
  
</details>

**config_usercommands** specifies startup commands for i3:

<details>
<summary>config_usercommands</summary>
<br>
  
```
#####################################
#  user specific i3 start commands  #
#####################################

#################################
# Authentication Agent (Polkit) #
#################################
# Only one agent should be active.

### Autodetect ###
exec --no-startup-id /usr/bin/lxpolkit

#################################
#  System Services & Settings   #
#################################

# Ensure keyboard settings persist after i3 restarts
# Change ONLY the layouts after -layout, keep the options and structure intact:
exec_always --no-startup-id setxkbmap -layout de,us,es,fr -option 'grp:alt_shift_toggle'

# Open new workspaces in tabbed layout
workspace_layout tabbed

# Set static background color
exec --no-startup-id xsetroot -solid "#333333"

# Set resolution - NOTE: You must edit or comment out accordingly!!!
# exec --no-startup-id xrandr --output "your_output" --mode "your_mode"
#exec --no-startup-id xrandr --output "DP-2" --mode "1920x1080"
```
  
</details>
