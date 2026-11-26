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

# ---------------------------------------------------------------------------
# Rofi wallpaper cache
# Rofi decodes + scales the image from the .rasi on EVERY start. Instead of the
# full-size wallpaper, each menu gets its own pre-scaled copy (built once per
# wallpaper change). The .rasi files keep their `height` scaling mode, so the
# layout stays identical; rofi just has a tiny file to decode.
#   ~/.cache/rofi_current_wallpaper.png stays untouched (hyprlock fallback etc.)
# ---------------------------------------------------------------------------
ROFI_WALL_SRC="$HOME/.cache/rofi_current_wallpaper.png"
ROFI_WALL_CACHE="$HOME/.cache/rofi-wall"

# Monitor: 2560x1440 @ 1.25 scale
RENDER_SCALE=1.25     # physical pixels per logical pixel
OVERSAMPLE=1.15       # safety margin for font-metric differences / sharpness

# menu name : max height (logical px) of the left image box, i.e. the full
# height of the right box at its configured number of listview lines
declare -A ROFI_BOX_HEIGHT=(
    [drun]=303
    [wallpaper]=309
    [config]=209
    [cliphist]=209
    [mount]=215
)

build_rofi_wall_cache() {
    local src="$1" name h out
    [ -f "$src" ] || return 1
    mkdir -p "$ROFI_WALL_CACHE"
    for name in "${!ROFI_BOX_HEIGHT[@]}"; do
        # target height in physical pixels, rounded to an even number
        h=$(awk -v h="${ROFI_BOX_HEIGHT[$name]}" -v s="$RENDER_SCALE" -v o="$OVERSAMPLE" \
            'BEGIN { v = int(h * s * o + 0.5); if (v % 2) v++; print v }')
        out="$ROFI_WALL_CACHE/$name.png"
        # keep aspect ratio, never upscale, write atomically (tmp + mv)
        ffmpeg -y -v error -i "$src" \
            -vf "scale=-2:'min(ih,${h})':flags=lanczos" \
            -frames:v 1 -update 1 "$out.tmp.png" \
            && mv -f "$out.tmp.png" "$out"
    done
}

# Standalone mode (first-time setup, restore-wallpaper.sh, manual rebuild):
#   wallpaper_selector_mpv.sh --rebuild-cache
if [ "$1" = "--rebuild-cache" ]; then
    build_rofi_wall_cache "$ROFI_WALL_SRC"
    exit $?
fi

# Self-heal: make sure this script's own menu has its cached image
[ -f "$ROFI_WALL_CACHE/wallpaper.png" ] || build_rofi_wall_cache "$ROFI_WALL_SRC"

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
    cp -f "$IMAGE_TO_USE" "$ROFI_WALL_SRC"

    # C2) Pre-scaled per-menu copies for rofi (background job, atomic writes)
    build_rofi_wall_cache "$IMAGE_TO_USE" >/dev/null 2>&1 &

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

    # F) Hyprlock-Hintergrund: bei .mp4 das Video selbst, sonst das Standbild.
    #    Das Video wird nur gesetzt, wenn hyprlock mit FFmpeg gebaut ist (Fork mit
    #    Video-Support, linkt libavcodec) - sonst bleibt es beim Standbild.
    #    '#' wird zu '##' escaped, weil hyprlang '#' sonst als Kommentar liest.
    LOCK_BG="$HOME/.cache/rofi_current_wallpaper.png"
    if [[ "$selected" =~ \.(mp4|MP4)$ ]] && ldd "$(command -v hyprlock)" 2>/dev/null | grep -q 'libavcodec'; then
        LOCK_BG="$WALLPAPER_PATH"
    fi
    printf '$LOCK_BG = %s\n' "${LOCK_BG//#/##}" > "$HOME/.cache/hyprlock_bg.conf"
fi
