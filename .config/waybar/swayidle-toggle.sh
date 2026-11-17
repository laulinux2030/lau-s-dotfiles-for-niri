#!/usr/bin/env bash

LOCK=/home/lau/.config/niri/scripts/hyprlock30min.sh
ICON_ON="󰒲 +"    # swayidle running   (placeholder: lock)
ICON_OFF="󰒳 -"   # swayidle off       (placeholder: unlock)

is_running() { pgrep -x swayidle >/dev/null; }

start() {
    setsid -f swayidle -w \
        timeout 600 "$LOCK" \
        lock "$LOCK" \
        before-sleep "$LOCK; sleep 1" >/dev/null 2>&1
}

case "$1" in
    toggle)
        if is_running; then
            pkill -x swayidle
        else
            start
        fi
        sleep 0.2                 # give the process time to start/exit
        pkill -RTMIN+8 waybar     # refresh the module immediately
        ;;
    *)
        if is_running; then
            printf '{"text":"%s","tooltip":"swayidle active","class":"active"}\n' "$ICON_ON"
        else
            printf '{"text":"%s","tooltip":"swayidle inactive","class":"inactive"}\n' "$ICON_OFF"
        fi
        ;;
esac
