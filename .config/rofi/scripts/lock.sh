#!/usr/bin/env bash

# --- Logging (so we can see what actually happens) ---
LOG="/tmp/lock.log"
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== $(date) ==="
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "PATH=$PATH"

FRAME_CACHE="/tmp/swaylock_frame.png"
ROFI_CACHE="$HOME/.cache/rofi_current_wallpaper.png"
CURRENT_FILE="$HOME/.cache/current_wallpaper"

# --- 1. Pick the image source ---
IMG=""
if [ -f "$CURRENT_FILE" ]; then
    WALLPAPER="$(cat "$CURRENT_FILE")"
    echo "WALLPAPER=$WALLPAPER"
    if [ -f "$WALLPAPER" ]; then
        case "$WALLPAPER" in
            *.mp4|*.MP4)
                ffmpeg -y -ss 00:00:01 -i "$WALLPAPER" -vframes 1 "$FRAME_CACHE" \
                    && IMG="$FRAME_CACHE"
                ;;
            *.gif|*.GIF|*.webp|*.WEBP)
                ffmpeg -y -i "$WALLPAPER" -vframes 1 "$FRAME_CACHE" \
                    && IMG="$FRAME_CACHE"
                ;;
            *)
                IMG="$WALLPAPER"
                ;;
        esac
    fi
fi

[ -f "$IMG" ] || IMG="$ROFI_CACHE"
[ -f "$IMG" ] || IMG="/tmp/matugen_frame.png"
echo "IMG=$IMG"

# --- 2. Locate a working lock binary ---
SWAYLOCK_BIN=""
for cand in swaylock swaylock-effects; do
    if command -v "$cand" >/dev/null 2>&1; then
        SWAYLOCK_BIN="$(command -v "$cand")"
        echo "Found lock binary: $SWAYLOCK_BIN"
        break
    fi
done

if [ -z "$SWAYLOCK_BIN" ]; then
    echo "ERROR: no swaylock binary found in PATH"
    notify-send "Lock failed" "No swaylock binary in PATH" 2>/dev/null
    exit 1
fi

# --- 3. niri: avoid the red-screen flash (best-effort) ---
niri msg action do-screen-transition >/dev/null 2>&1 || true

# --- 4. Launch ---
"$SWAYLOCK_BIN" \
    --config "$HOME/.config/swaylock/config" \
    --image "$IMG"
echo "swaylock exited with code $?
