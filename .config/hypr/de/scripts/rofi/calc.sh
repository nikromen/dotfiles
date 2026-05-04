#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "calculator with live preview (fzf + qalc)" \
    "Opens a floating terminal with fzf. Type expressions and see results
in real-time. Enter copies the result to clipboard. Supports currency
conversion, unit conversion, and math (powered by qalculate).

Examples: 500 EUR to CZK, sqrt(144), 30% of 1500, 5 kg to lbs" && exit 0

# shellcheck disable=SC2016
alacritty --title rofi-calc -e bash -c '
    result=$(fzf --print-query \
        --preview "qalc -t {q} 2>/dev/null || echo \"...\"" \
        --preview-window=up:1:wrap \
        --history="$HOME/.cache/rofi-calc-history" \
        --prompt="Calc> " \
        --header="Type expression. Enter to copy result." \
        < /dev/null | head -1)
    if [ -n "$result" ]; then
        answer=$(qalc -t "$result" 2>/dev/null)
        echo -n "$answer" | wl-copy
        notify-send -t 3000 "= $answer" "Copied to clipboard"
    fi
'
