#!/bin/bash

source "$HOME/.local/lib/help.sh"
set -e

HELP_DETAILS="Commands:
  up     Increase volume by 5%
  down   Decrease volume by 5%
  get    Print current volume percentage
  mute   Toggle mute

Options:
  -n, --notify   Send desktop notification after change
  -h, --help     Show this message"

usage() { show_help "control audio volume via PipeWire" "$HELP_DETAILS"; }

if [ -z "$1" ]; then
    usage >&2
    exit 1
fi

get() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}'
}

_icon() {
    local volume=$1
    local icon_path="$WM_ICONS/volume"
    if [[ "$volume" == 0 ]]; then
        echo "$icon_path/mute.png"
    elif [[ "$volume" -lt 30 ]]; then
        echo "$icon_path/low.png"
    elif [[ "$volume" -lt 60 ]]; then
        echo "$icon_path/mid.png"
    else
        echo "$icon_path/high.png"
    fi
}

_notify() {
    local volume
    volume=$(get)
    notify-send -e -h string:x-canonical-private-synchronous:volume_notify -h "int:value:$volume" -u low -i "$(_icon "$volume")" "$volume%"

    if [[ "$volume" != 0 ]]; then
        pw-cat --playback "$WM_AUDIO/bell.oga"
    fi
}

_unmute_if_needed() {
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    fi
}


notify=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        -n | --notify)
            notify=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

case "$1" in
    up)
        _unmute_if_needed
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        if [ "$notify" = true ]; then
            _notify
        fi
        ;;
    down)
        _unmute_if_needed
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        if [ "$notify" = true ]; then
            _notify
        fi
        ;;
    get)
        get
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        if [ "$notify" = true ]; then
            if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"; then
                notify-send -e -h string:x-canonical-private-synchronous:volume_notify -u low -i "$(_icon 0)" "Muted"
            else
                _notify
            fi
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac
