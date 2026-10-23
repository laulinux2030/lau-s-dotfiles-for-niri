#!/bin/bash

CONFIG="$HOME/.config/niri/config.kdl"
# Aktuellen Wert auslesen (sucht nach reference-luminance)
current=$(grep -oP 'reference-luminance \K[0-9]+' "$CONFIG" | head -n 1)

[ -z "$current" ] && current=200

if [ "$1" = "up" ]; then
    new=$((current + 10))
    [ $new -gt 1000 ] && new=1000
elif [ "$1" = "down" ]; then
    new=$((current - 10))
    [ $new -lt 50 ] && new=50
elif [ "$1" = "get" ]; then
    echo "{\"text\": \"󰃟 ${current}nits\", \"tooltip\": \"HDR Reference Luminance: ${current} nits\"}"
    exit 0
fi

# Wert in der config.kdl ersetzen
sed -i -E "s/(reference-luminance )[0-9]+/\1$new/" "$CONFIG"

# Niri anweisen, die Konfiguration neu zu laden
niri msg action reload-config
