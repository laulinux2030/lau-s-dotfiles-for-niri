#!/usr/bin/env bash
set -euo pipefail

wipe_label="Wipe History"

selection=$(
	{ printf '%s\n' "$wipe_label"; cliphist list; } |
	rofi -dmenu \
		-theme "$HOME/.config/rofi/cliphist.rasi" \
		-p Clipboard
) || exit 0

[[ -z "$selection" ]] && exit 0

if [[ "$selection" == "$wipe_label" ]]; then
	cliphist wipe
	notify-send "Clipboard" "History wiped." 2>/dev/null || true
else
	printf '%s' "$selection" | cliphist decode | wl-copy
	notify-send "Clipboard" "Copied to Clipboard." 2>/dev/null || true
fi

