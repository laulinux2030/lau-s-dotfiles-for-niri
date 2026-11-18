#!/usr/bin/env bash

LOCK=/home/lau/.config/niri/scripts/hyprlock30min.sh
TOGGLE=/home/lau/.config/waybar/swayidle-toggle.sh
THEME=/home/lau/.config/rofi/mount.rasi    # point this at one of your existing menu themes
DEADLINE=${XDG_RUNTIME_DIR:-/tmp}/lock-timer.deadline

ICON_ON="󰒳"       # <- keep your own symbols here
ICON_OFF="󰒲"
ICON_TIMER=$'\uf017'
ICON_CANCEL=$'\uf00d'

theme_args=()
[[ -f $THEME ]] && theme_args=(-theme "$THEME")

if pgrep -x swayidle >/dev/null; then
    TOGGLE_LABEL="$ICON_ON  Turn swayidle off"
else
    TOGGLE_LABEL="$ICON_OFF  Turn swayidle on"
fi
CANCEL_LABEL="$ICON_CANCEL  Cancel lock timer"

entries=("$TOGGLE_LABEL")
systemctl --user is-active --quiet lock-timer.timer && entries+=("$CANCEL_LABEL")

choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "$ICON_TIMER  Lock in" \
    "${theme_args[@]}" -theme-str 'entry { placeholder: "minutes"; }')
[[ -z $choice ]] && exit 0

case "$choice" in
    "$TOGGLE_LABEL")
        "$TOGGLE" toggle
        ;;
    "$CANCEL_LABEL")
        systemctl --user stop lock-timer.timer
        rm -f "$DEADLINE"
        pkill -RTMIN+8 waybar
        notify-send "Lock timer" "Cancelled"
        ;;
    *)
        if [[ $choice =~ ^[0-9]+$ ]] && (( 10#$choice > 0 )); then
            min=$((10#$choice))
            systemctl --user stop lock-timer.timer 2>/dev/null
            if systemd-run --user --quiet --collect --unit=lock-timer --on-active="${min}min" \
                --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" --setenv=PATH="$PATH" "$LOCK"; then
                echo $(( $(date +%s) + min * 60 )) > "$DEADLINE"
                pkill -RTMIN+8 waybar
                notify-send "Lock timer" "Locking in $min min"
            else
                notify-send "Lock timer" "Could not start the timer"
            fi
        else
            notify-send "Lock timer" "Please enter a number of minutes"
        fi
        ;;
esac
