#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "switch to a git repository in a new terminal" \
    "Finds git repos in home directory, opens a terminal in the selected one." && exit 0

selected=$(fd -t d '\.git$' "$HOME" --max-depth 4 --hidden \
    | sed 's|/.git/$||' \
    | rofi -dmenu -matching fuzzy -sort -i -p "Git repo")

[ -z "$selected" ] && exit 0
alacritty --working-directory "$selected"
