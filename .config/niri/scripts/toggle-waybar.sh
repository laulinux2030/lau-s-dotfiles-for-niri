#!/usr/bin/env bash

if pgrep -x waybar >/dev/null; then
    pkill -x waybar
else
    setsid -f "$HOME/.config/waybar/launch.sh" >/dev/null 2>&1
fi
