#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "web search via rofi with history" \
    "Opens a floating terminal with fzf. Type a query, press Enter to
open Google in default browser. Previous searches are shown and can
be reused (arrow keys to navigate history)." && exit 0

# shellcheck disable=SC2016
alacritty --title rofi-websearch -e bash -c '
    query=$(fzf --print-query \
        --history="$HOME/.cache/rofi-websearch-history" \
        --prompt="Search> " \
        --header="Type query. Enter to search Google. Up/Down for history." \
        < /dev/null | head -1)
    if [ -n "$query" ]; then
        encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote_plus(sys.argv[1]))" "$query")
        nohup xdg-open "https://google.com/search?q=$encoded" >/dev/null 2>&1 &
    fi
'
