#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "screenshot and screen recording menu" \
    "Quick menu for screenshots (flameshot) and recordings (wf-recorder).
Includes full/region/window screenshots and region MP4/GIF recording." && exit 0

if pgrep -x wf-recorder > /dev/null; then
    action=$(printf "Stop recording" | rofi -dmenu -p "Recording active")
    if [[ "$action" == "Stop recording" ]]; then
        killall -s SIGINT wf-recorder
        notify-send "Recording saved" "$(find ~/Videos -maxdepth 1 -name 'recording-*' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
    fi
    exit 0
fi

ACTIONS="Screenshot: Full screen
Screenshot: Select region
Screenshot: Current window
Record: Select region (MP4)
Record: Select region (GIF)"

action=$(echo "$ACTIONS" | rofi -dmenu -p "Capture")
[ -z "$action" ] && exit 0

OUTDIR="$HOME/Videos"
mkdir -p "$OUTDIR"
timestamp=$(date +%Y%m%d-%H%M%S)

case "$action" in
    "Screenshot: Full screen")
        flameshot full -c
        ;;
    "Screenshot: Select region")
        flameshot gui
        ;;
    "Screenshot: Current window")
        flameshot screen -c
        ;;
    "Record: Select region (MP4)")
        region=$(slurp)
        [ -z "$region" ] && exit 0
        wf-recorder -g "$region" -f "$OUTDIR/recording-$timestamp.mp4" &
        notify-send "Recording started" "MP4 | Press keybind again to stop"
        ;;
    "Record: Select region (GIF)")
        region=$(slurp)
        [ -z "$region" ] && exit 0
        wf-recorder -g "$region" -c gif -f "$OUTDIR/recording-$timestamp.gif" &
        notify-send "Recording started" "GIF | Press keybind again to stop"
        ;;
esac
