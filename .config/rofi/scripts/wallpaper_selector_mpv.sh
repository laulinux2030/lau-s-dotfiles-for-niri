#!/usr/bin/env bash

# Configurations
WALLPAPER_DIR="/mnt/ec3a6598-2b60-49d9-9394-1407c352989c/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
FRAME_CACHE="/tmp/matugen_frame.png"
LOG_FILE="/tmp/matugen.log"
STATE_FILE="$HOME/.cache/wallpaper_state"

# Verzeichnisse erstellen
mkdir -p "$CACHE_DIR"
mkdir -p "$(dirname "$STATE_FILE")"

# Locate matugen binary explicitly
MATUGEN_BIN="$(command -v matugen || echo "$HOME/.cargo/bin/matugen" || echo "$HOME/.local/bin/matugen")"

# 1. Build thumbnail cache and Rofi image list
rofi_input=""
while IFS= read -r -d '' img; do
    [ -e "$img" ] || continue

    filename=$(basename "$img")
    thumb="$CACHE_DIR/${filename}.png"

    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        if [[ "$img" =~ \.(mp4|MP4)$ ]]; then
            ffmpeg -y -ss 00:00:01 -i "$img" -vframes 1 -s 250x140 "$thumb" &>/dev/null
        else
            ffmpeg -y -i "$img" -vframes 1 -s 250x140 "$thumb" &>/dev/null
        fi
    fi

    rofi_input+="${filename}\x00icon\x1f${thumb}\n"
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.mp4" \) -print0)

# 2. Open Rofi menu
selected=$(echo -ne "$rofi_input" | rofi -dmenu \
    -p "Wallpaper" \
    -show-icons \
    -theme "$HOME/.config/rofi/wallpaper.rasi")

# 3. Apply selected wallpaper/video
if [ -n "$selected" ]; then
    WALLPAPER_PATH="$WALLPAPER_DIR/$selected"
    echo "$WALLPAPER_PATH" > "$HOME/.cache/current_wallpaper"

    # Alte mpvpaper Instanzen sauber beenden
    pkill -SIGTERM -x mpvpaper
    pkill -x waybar
    sleep 0.5

    # A) mpvpaper rendert das Backdrop (niri platziert die Layer-Surface per layer-rule
    #    im Overview-Backdrop). image-display-duration=inf hält Standbilder dauerhaft.
    nohup mpvpaper \
        --loop \
        -o "no-audio loop-file=inf image-display-duration=inf hwdec=nvdec hwdec-codecs=all cache=yes demuxer-readahead-secs=20 panscan=1.0" \
        "*" "$WALLPAPER_PATH" \
        >/dev/null 2>&1 &

    # B) Standbild für Matugen und Rofi extrahieren
    if [[ "$selected" =~ \.(mp4|MP4)$ ]]; then
        ffmpeg -y -ss 00:00:01 -i "$WALLPAPER_PATH" -vframes 1 "$FRAME_CACHE" &>/dev/null
        IMAGE_TO_USE="$FRAME_CACHE"
    elif [[ "$selected" =~ \.(gif|GIF)$ ]]; then
        ffmpeg -y -i "$WALLPAPER_PATH" -vframes 1 "$FRAME_CACHE" &>/dev/null
        IMAGE_TO_USE="$FRAME_CACHE"
    else
        IMAGE_TO_USE="$WALLPAPER_PATH"
    fi

    # C) Standbild für Rofi-Theme bereitstellen
    cp -f "$IMAGE_TO_USE" "$HOME/.cache/rofi_current_wallpaper.png"

    # D) Matugen generiert die Farben aus dem Standbild
    "$MATUGEN_BIN" image "$IMAGE_TO_USE" -m dark --source-color-index 0 > "$LOG_FILE" 2>&1

    sleep 0.1

    # E) State für Reboot speichern
    cat > "$STATE_FILE" << EOF
WALLPAPER_PATH="$WALLPAPER_PATH"
SELECTED="$selected"
IMAGE_TO_USE="$IMAGE_TO_USE"
IS_VIDEO=$( [[ "$selected" =~ \.(mp4|MP4)$ ]] && echo "true" || echo "false" )
IS_GIF=$( [[ "$selected" =~ \.(gif|GIF)$ ]] && echo "true" || echo "false" )
EOF

    echo "Wallpaper state saved to $STATE_FILE" >> "$LOG_FILE"

    sleep 0.5
    nohup waybar >/dev/null 2>&1 &
fi
