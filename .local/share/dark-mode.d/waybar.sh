#!/bin/bash
cp ~/.config/waybar/style-dark.css ~/.config/waybar/style.css
pkill -SIGUSR2 waybar || true
