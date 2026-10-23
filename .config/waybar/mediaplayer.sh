#!/bin/bash

# Fetch status, artist, and title
status=$(playerctl status 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

escape_json() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if [ "$status" = "Playing" ] && [ -n "$title" ]; then
    icon="󰝚"
    display_title="${title:0:25}"
    if [ -n "$artist" ]; then
        tooltip="${artist}: ${title}"
    else
        tooltip="${title}"
    fi

elif [ "$status" = "Paused" ] && [ -n "$title" ]; then
    icon="󰏤"
    display_title="${title:0:25}"
    if [ -n "$artist" ]; then
        tooltip="${artist}\n${title} (Pausiert)"
    else
        tooltip="${title} (Pausiert)"
    fi

else
    icon="󰏤"
    display_title="No media"
    tooltip="No Mediaplayer active"
fi

text_esc=$(escape_json "$icon $display_title")
tooltip_esc=$(escape_json "$tooltip")

printf '{"text": "%s", "tooltip": "%s"}\n' "$text_esc" "$tooltip_esc"
