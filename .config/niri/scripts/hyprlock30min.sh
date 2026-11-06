#!/bin/sh
# Lock the screen; if still locked 30 minutes later, put the monitors to standby.
pidof hyprlock >/dev/null && exit 0
hyprlock &
hl=$!
(
    sleep 1800
    kill -0 "$hl" 2>/dev/null && niri msg action power-off-monitors
) >/dev/null 2>&1 &
