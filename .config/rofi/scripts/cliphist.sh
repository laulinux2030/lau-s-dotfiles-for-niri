#!/usr/bin/env bash
set -euo pipefail
 
selection=$(
	{ printf '\tWipe History\n'; cliphist list; } |
	rofi -dmenu \
		-theme "$HOME/.config/rofi/wallpaper.rasi" \
		-theme-str '' \
		-p Clipboard \
		-display-columns 2
)
 
[[ -z "$selection" ]] && exit 0
 
if [[ "$selection" == $'\t'* ]]; then
	cliphist wipe
	notify-send "Clipboard" "History wiped." 2>/dev/null || true
else
	echo "$selection" | cliphist decode | wl-copy
	notify-send "Clipboard" "Copied to Clipboard." 2>/dev/null || true
fi
 

