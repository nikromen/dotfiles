#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "emoji and symbol picker with fuzzy search" \
    "Searches through Unicode emoji and custom symbols.
Selected character is copied to clipboard via wl-copy." && exit 0

DATA_DIR="$HOME/.local/share/rofi"
selected=$(cat "$DATA_DIR/emoji.txt" "$DATA_DIR/custom-emoji.txt" 2>/dev/null \
    | grep -v "^Generated" \
    | rofi -dmenu -matching normal -sort -i -p "Emoji")

[ -z "$selected" ] && exit 0

char="${selected%% *}"
echo -n "$char" | wl-copy
notify-send -t 1500 "$char" "Copied to clipboard"
