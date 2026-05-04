#!/bin/bash
SETTINGS_FILES=(
    "$HOME/.config/Code/User/settings.json"
    "$HOME/.config/Cursor/User/settings.json"
)

for f in "${SETTINGS_FILES[@]}"; do
    if [ -f "$f" ]; then
        tmp=$(mktemp)
        jq '."workbench.colorTheme" = "Catppuccin Mocha"' "$f" > "$tmp" && mv "$tmp" "$f"
    fi
done
