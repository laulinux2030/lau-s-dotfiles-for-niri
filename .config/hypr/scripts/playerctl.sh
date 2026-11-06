#!/bin/bash
# Prints only the title of the currently loaded track.
# Outputs nothing (blank label in hyprlock) when no player is running
# or when the player has no track loaded.

# Bail out silently if playerctl is missing or no player is active
command -v playerctl >/dev/null 2>&1 || exit 0
playerctl status >/dev/null 2>&1 || exit 0

title=$(playerctl metadata --format '{{ title }} – {{ artist }}' 2>/dev/null)

# Blank label if the player is up but nothing is loaded
[ -z "$title" ] && exit 0

printf '%s\n' "$title"
