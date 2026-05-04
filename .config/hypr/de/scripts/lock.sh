#!/bin/bash

source "$HOME/.local/lib/help.sh"
check_help "$1" && show_help "lock screen with hyprlock and restart waybar after unlock" && exit 0

hyprlock

# TODO: find a better way to fix waybar workspace display after lock
"$WM_SCRIPTS/workspaces.lua" --refresh

if pgrep -x waybar > /dev/null; then
    killall waybar
    waybar &
fi
