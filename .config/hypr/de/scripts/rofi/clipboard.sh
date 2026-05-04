#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "clipboard history via copyq and rofi" \
    "Shows clipboard history from copyq. Selected entry is placed on clipboard." && exit 0

max_items=30
selected=$(copyq eval "
    var result = [];
    for (var i = 0; i < Math.min(size(), $max_items); i++) {
        var text = str(read(i)).replace(/\n/g, ' ').substring(0, 100);
        result.push(i + ': ' + text);
    }
    print(result.join('\n'));
" | rofi -dmenu -matching fuzzy -i -p "Clipboard")

[ -z "$selected" ] && exit 0

index="${selected%%:*}"
copyq select "$index"
