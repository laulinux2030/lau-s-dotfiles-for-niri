#!/usr/bin/env bash
 
# Definition der Optionen mit Icons
options="󰤄  Sleep\n󰗽  Log Out\n󰜉  Reboot\n󰐥  Power Off"
 
# Rofi aufrufen und Auswahl abfangen
chosen=$(echo -e "$options" | rofi -dmenu -i -theme "$HOME/.config/rofi/config.rasi" -theme-str 'inputbar { enabled: false; }')
 
# Nur den reinen Text (ohne Icons/Leerzeichen am Anfang) extrahieren
action=$(echo "$chosen" | sed 's/^[[:space:]]*[[:alnum:]]*[[:space:]]*//')
 
# Fallback, falls Regex das Icon nicht komplett erfasst: Direkt auf bekannte Keywords matchen
case "$chosen" in
    *Power*Off*)
        systemctl poweroff
        ;;
    *Reboot*)
        systemctl reboot
        ;;
    *Log*Out*)
        niri msg action quit
        ;;
    *Sleep*)
        systemctl suspend
        ;;
esac

