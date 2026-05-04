#!/bin/bash
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
    tmux set -g @catppuccin_flavor "mocha"
    tmux source-file ~/.config/tmux/tmux.conf
fi
