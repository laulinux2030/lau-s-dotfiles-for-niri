#!/bin/bash

# Wetter für Rostock, Deutschland
CITY="Rostock"

# Aktuelle Temperatur und Icon
current_data=$(curl -s "https://wttr.in/${CITY}?format=%C+%t&lang=de")
temp=$(echo "$current_data" | grep -oE '[+-]?[0-9]+°C' | head -1)
condition=$(echo "$current_data" | sed "s/$temp//" | xargs)

# Aktuelle Stunde ermitteln (für Tag/Nacht-Erkennung)
current_hour=$(date +%H)

# Ist es Tag? (6:00 - 20:00 Uhr)
if [ "$current_hour" -ge 6 ] && [ "$current_hour" -lt 20 ]; then
    is_day=true
else
    is_day=false
fi

# Icon für aktuelles Wetter mit Tag/Nacht-Unterscheidung
case "$condition" in
    *"Sunny"*|*"Clear"*|*"Sonnig"*|*"Klar"*)
        if [ "$is_day" = true ]; then
            icon="󰖙"  # Sonne (Tag)
        else
            icon="󰖔"  # Mondsichel (Nacht)
        fi
        ;;
    *"Partly"*|*"Teilweise"*)
        if [ "$is_day" = true ]; then
            icon="󰖕"  # Teils bewölkt (Tag)
        else
            icon="󰖔"  # Mond mit Wolken (Nacht)
        fi
        ;;
    *"Cloudy"*|*"Wolkig"*)
        if [ "$is_day" = true ]; then
            icon="󰖐"  # Bewölkt (Tag)
        else
            icon="󰖔"  # Mond mit Wolken (Nacht)
        fi
        ;;
    *"Overcast"*|*"Bedeckt"*)
        if [ "$is_day" = true ]; then
            icon="󰖐"  # Bedeckt (Tag)
        else
            icon="󰖔"  # Mond mit Wolken (Nacht)
        fi
        ;;
    *"Rain"*|*"Regen"*|*"Drizzle"*|*"Niesel"*)
        if [ "$is_day" = true ]; then
            icon="󰖗"  # Regen (Tag)
        else
            icon="󰖝"  # Mond mit Regen (Nacht)
        fi
        ;;
    *"Shower"*|*"Schauer"*)
        if [ "$is_day" = true ]; then
            icon="󰼃"  # Regenschauer (Tag)
        else
            icon="󰖝"  # Mond mit Regen (Nacht)
        fi
        ;;
    *"Thunder"*|*"Gewitter"*)
        if [ "$is_day" = true ]; then
            icon="󰖓"  # Gewitter (Tag)
        else
            icon="󰖓"  # Gewitter (Nacht - gleiches Symbol)
        fi
        ;;
    *"Snow"*|*"Schnee"*)
        if [ "$is_day" = true ]; then
            icon="󰖘"  # Schnee (Tag)
        else
            icon="󰖞"  # Mond mit Schnee (Nacht)
        fi
        ;;
    *"Mist"*|*"Fog"*|*"Nebel"*)
        if [ "$is_day" = true ]; then
            icon="󰖑"  # Nebel (Tag)
        else
            icon="󰖔"  # Mond mit Nebel (Nacht)
        fi
        ;;
    *)
        if [ "$is_day" = true ]; then
            icon="󰖕"  # Default (Tag)
        else
            icon="󰖔"  # Default (Nacht)
        fi
        ;;
esac

# Tooltip mit aktuellen Wetterdaten
tooltip="${CITY}: $condition, $temp"

# JSON-Ausgabe für Waybar
echo "{\"text\": \"$icon $temp\", \"tooltip\": \"$tooltip\"}"