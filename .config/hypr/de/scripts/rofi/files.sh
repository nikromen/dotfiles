#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "find and open files with fuzzy search" \
    "Opens a floating terminal with fzf. Searches files in home directory
using fd with instant fuzzy filtering. Enter opens the selected file
with xdg-open." && exit 0

# shellcheck disable=SC2016
alacritty --title rofi-files -e bash -c '
    selected=$(fd . "$HOME" --type f --max-depth 5 --hidden \
        --exclude .git --exclude node_modules --exclude .cache \
        | fzf --prompt="File> " \
              --preview="file {} | cut -d: -f2-" \
              --preview-window=up:1:wrap \
              --header="Type to filter. Enter to open.")
    if [ -n "$selected" ]; then
        nohup xdg-open "$selected" >/dev/null 2>&1 &
    fi
'
