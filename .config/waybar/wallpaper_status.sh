#!/bin/bash

STATE_FILE="$HOME/.cache/wallpaper_state"

if [ -f "$STATE_FILE" ]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
else
    SELECTED="No wallpaper set"
fi

escape_json() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if [ "$IS_VIDEO" = "true" ]; then
    icon="󰃽 "
elif [ "$IS_GIF" = "true" ]; then
    icon="󰵸 "
else
    icon="󰋩 "
fi

# Truncate long filenames for the bar, full name stays in the tooltip
display_name="${SELECTED:0:30}"
[ "${#SELECTED}" -gt 30 ] && display_name="${display_name}…"

text_esc=$(escape_json "$icon$display_name")
tooltip_esc=$(escape_json "$SELECTED")

printf '{"text": "%s", "tooltip": "%s"}\n' "$text_esc" "$tooltip_esc"
