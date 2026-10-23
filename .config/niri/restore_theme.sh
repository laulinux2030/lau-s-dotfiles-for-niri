#!/bin/bash

CACHE_FILE="$HOME/.cache/current_wallpaper"

# Matugen Pfad genau wie im Wallpaper-Skript ermitteln
MATUGEN_BIN="$(command -v matugen || echo "$HOME/.cargo/bin/matugen" || echo "$HOME/.local/bin/matugen")"
LOG_FILE="/tmp/matugen.log"
FRAME_CACHE="/tmp/matugen_frame.png"

if [ -f "$CACHE_FILE" ]; then
    WALLPAPER=$(cat "$CACHE_FILE")
    
    if [ -f "$WALLPAPER" ]; then
        # 1. Clean up any existing swww-daemon instances to prevent conflicts
        killall swww-daemon 2>/dev/null
        sleep 0.2

        # 2. Start normal desktop wallpaper daemon and apply image
        swww-daemon &
        sleep 0.3
        swww img "$WALLPAPER"

        # 3. Start secondary overview-backdrop daemon with custom namespace and apply image
        swww-daemon --namespace overview-backdrop &
        sleep 0.3
        swww img "$WALLPAPER" --namespace overview-backdrop

        # 4. Generate Matugen theme colors (mit GIF/Frame-Handhabung wie im Wallpaper-Skript)
        if [[ "$WALLPAPER" =~ \.(gif|GIF)$ ]]; then
            ffmpeg -y -i "$WALLPAPER" -vframes 1 "$FRAME_CACHE" &>/dev/null
            "$MATUGEN_BIN" image "$FRAME_CACHE" -m dark --source-color-index 0 > "$LOG_FILE" 2>&1
        else
            "$MATUGEN_BIN" image "$WALLPAPER" -m dark --source-color-index 0 > "$LOG_FILE" 2>&1
        fi
    fi
fi