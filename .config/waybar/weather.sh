#!/bin/bash

# Wetter für Rostock, Deutschland (Open-Meteo, kein API-Key nötig)
CITY="Rostock"
LAT="54.09"
LON="12.10"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather.json"
mkdir -p "$(dirname "$CACHE")"

# Bei Fehlern: letzte gute Ausgabe zeigen statt kaputtem JSON
fallback() {
    if [ -f "$CACHE" ]; then
        cat "$CACHE"
    else
        echo "{\"text\": \"N/A\", \"tooltip\": \"$1\"}"
    fi
    exit 0
}

command -v jq >/dev/null || fallback "jq fehlt (sudo apt install jq)"

# Aktuelle Daten holen (Timeout + HTTP-Fehler -> leere Ausgabe)
data=$(curl -sf --max-time 10 \
    "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,weather_code,is_day&timezone=auto")
[ -z "$data" ] && fallback "Wetterdaten nicht verfügbar"

read -r raw_temp code is_day < <(echo "$data" | jq -r '.current | "\(.temperature_2m) \(.weather_code) \(.is_day)"')
if [ -z "$raw_temp" ] || [ "$raw_temp" = "null" ] || [ "$code" = "null" ]; then
    fallback "Ungültige Wetterdaten"
fi

# Temperatur auf ganze Grad runden
temp=$(awk -v t="$raw_temp" 'BEGIN { printf "%d°C", (t < 0) ? t - 0.5 : t + 0.5 }')

# WMO-Wettercode -> Beschreibung und Icons (Tag / Nacht)
case "$code" in
    0)              condition="Klar";              day_icon="󰖙"; night_icon="󰖔" ;;
    1)              condition="Überwiegend klar";  day_icon="󰖙"; night_icon="󰖔" ;;
    2)              condition="Teilweise bewölkt"; day_icon="󰖕"; night_icon="󰖔" ;;
    3)              condition="Bedeckt";           day_icon="󰖐"; night_icon="󰖔" ;;
    45|48)          condition="Nebel";             day_icon="󰖑"; night_icon="󰖔" ;;
    51|53|55|56|57) condition="Nieselregen";       day_icon="󰖗"; night_icon="󰖝" ;;
    61|63|65|66|67) condition="Regen";             day_icon="󰖗"; night_icon="󰖝" ;;
    71|73|75|77)    condition="Schnee";            day_icon="󰖘"; night_icon="󰖞" ;;
    80|81|82)       condition="Regenschauer";      day_icon="󰼃"; night_icon="󰖝" ;;
    85|86)          condition="Schneeschauer";     day_icon="󰖘"; night_icon="󰖞" ;;
    95|96|99)       condition="Gewitter";          day_icon="󰖓"; night_icon="󰖓" ;;
    *)              condition="Unbekannt";         day_icon="󰖕"; night_icon="󰖔" ;;
esac

if [ "$is_day" = "1" ]; then
    icon="$day_icon"
else
    icon="$night_icon"
fi

# Tooltip mit aktuellen Wetterdaten
tooltip="${CITY}: $condition, $temp"

# JSON-Ausgabe für Waybar (gleichzeitig als Fallback zwischenspeichern)
echo "{\"text\": \"$icon $temp\", \"tooltip\": \"$tooltip\"}" | tee "$CACHE"
