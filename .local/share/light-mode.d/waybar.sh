#!/bin/bash
cp ~/.config/waybar/style-light.css ~/.config/waybar/style.css
pkill -SIGUSR2 waybar || true
