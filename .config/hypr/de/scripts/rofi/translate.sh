#!/bin/bash

source "$HOME/.local/lib/help.sh"

check_help "$1" && show_help "translate text via Google Translate (live preview)" \
    "Opens a floating terminal with fzf. Type text and see the translation
in real-time in the preview pane. Press Enter to copy result to clipboard.

Default: auto-detect -> Czech.
Prefix with language code to change target:
  en: text    -> translate to English
  de: text    -> translate to German
  cs: text    -> translate to Czech (default)

History is preserved between sessions." && exit 0

# shellcheck disable=SC2016
alacritty --title rofi-translate -e bash -c '
    result=$(fzf --print-query \
        --preview "
            q={q}
            [ -z \"\$q\" ] && echo \"Type text to translate...\" && exit
            target=\"cs\"
            if [[ \"\$q\" =~ ^([a-z]{2}):\\ (.+)$ ]]; then
                target=\"\${BASH_REMATCH[1]}\"
                q=\"\${BASH_REMATCH[2]}\"
            fi
            trans -b \":\$target\" \"\$q\" 2>/dev/null || echo \"...\"
        " \
        --preview-window=up:3:wrap \
        --history="$HOME/.cache/rofi-translate-history" \
        --prompt="Translate> " \
        --header="Prefix: en: de: fr: etc. Default: auto->cs. Enter copies result." \
        < /dev/null | head -1)
    if [ -n "$result" ]; then
        target="cs"
        if [[ "$result" =~ ^([a-z]{2}):\ (.+)$ ]]; then
            target="${BASH_REMATCH[1]}"
            result="${BASH_REMATCH[2]}"
        fi
        answer=$(trans -b ":$target" "$result" 2>/dev/null)
        if [ -n "$answer" ]; then
            echo -n "$answer" | wl-copy
            notify-send -t 3000 "= $answer" "Copied to clipboard"
        else
            notify-send -u critical "Translation failed" "$result"
        fi
    fi
'
