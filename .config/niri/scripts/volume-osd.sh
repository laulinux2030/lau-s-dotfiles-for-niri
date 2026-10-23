#!/bin/sh
# ~/.config/niri/volume-osd.sh
last=""
pactl subscribe | grep --line-buffered "on sink #" | while read -r _; do
  vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  [ "$vol" = "$last" ] && continue
  last="$vol"
  pct=$(echo "$vol" | awk '{printf "%d", $2*100}')
  echo "$vol" | grep -q MUTED && label="Muted" || label="Volume"
  notify-send -a volume-osd -t 1500 -h string:x-canonical-private-synchronous:volume \
    -h int:value:"$pct" "$label: ${pct}%"
done
