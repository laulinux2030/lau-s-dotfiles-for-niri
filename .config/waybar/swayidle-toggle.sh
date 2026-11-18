#!/usr/bin/env bash

LOCK=/home/lau/.config/niri/scripts/hyprlock30min.sh
DEADLINE=${XDG_RUNTIME_DIR:-/tmp}/lock-timer.deadline
LOG=${XDG_RUNTIME_DIR:-/tmp}/swayidle-start.log

ICON_ON="󰒲"
ICON_OFF="󰒳"

is_running() { pgrep -x swayidle >/dev/null; }

start() {
    setsid -f swayidle -w \
        timeout 600 "$LOCK" \
        lock "$LOCK" \
        before-sleep "$LOCK; sleep 1" >>"$LOG" 2>&1
}

case "$1" in
    toggle)
        if is_running; then
            pkill -x swayidle
        else
            start
            sleep 0.3
            is_running || notify-send "swayidle" "failed to start (see $LOG)"
        fi
        sleep 0.2
        pkill -RTMIN+8 waybar
        ;;
    *)
        left=""
        if systemctl --user is-active --quiet lock-timer.timer && [[ -r $DEADLINE ]]; then
            left=$(( ($(<"$DEADLINE") - $(date +%s) + 59) / 60 ))
            (( left < 1 )) && left=1
        fi

        if is_running; then
            icon=$ICON_ON;  class=active;   tip="swayidle active";   text="on"
        else
            icon=$ICON_OFF; class=inactive; tip="swayidle inactive"; text="off"
        fi

        if [[ -n $left ]]; then
            icon=$ICON_ON
            text="${left}m"
            tip+="\nlock in ${left} min"
        fi

        printf '{"text":"%s %s","tooltip":"%s","class":"%s"}\n' \
            "$icon" "$text" "$tip" "$class"
        ;;
esac
