#!/bin/bash

source "$HOME/.local/lib/help.sh"

HELP_DETAILS="Arguments:
  DIRECTORY   Path to directory with wallpaper images
  INTERVAL    Time in seconds between wallpaper changes
  FPS         Transition FPS (default: 60)

Options:
  -h, --help   Show this message"

usage() { show_help "rotate wallpapers at a set interval" "$HELP_DETAILS"; }

check_help "$1" && usage && exit 0

if [[ $# -lt 2 ]]; then
    usage >&2
    exit 1
fi

DIRECTORY=$1
INTERVAL=$2
FPS=${3:-60}

if [[ ! -d "$DIRECTORY" ]]; then
    echo "Directory not found: $DIRECTORY"
    exit 1
fi

if [[ ! $INTERVAL =~ ^[0-9]+$ ]]; then
    echo "Invalid interval: $INTERVAL"
    exit 1
fi

if [[ ! $FPS =~ ^[0-9]+$ ]]; then
    echo "Invalid FPS: $FPS"
    exit 1
fi

export SWWW_TRANSITION_FPS=$FPS
export SWWW_TRANSITION_STEP=2

shopt -s nullglob

while true; do
    readarray -t images < <(shuf -e "$DIRECTORY"/*)
    if [[ ${#images[@]} -eq 0 ]]; then
        echo "No images found in $DIRECTORY"
        exit 1
    fi
    for image in "${images[@]}"; do
        awww img "$image"
        sleep "$INTERVAL"
    done
done
