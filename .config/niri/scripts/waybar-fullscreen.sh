#!/usr/bin/env bash
# waybar-fullscreen.sh
# Kills Waybar when a window goes fullscreen on niri and brings it back
# when fullscreen ends. Start it once from niri (spawn-at-startup).

LAUNCH="$HOME/.config/waybar/launch.sh"
FLAG="${XDG_RUNTIME_DIR:-/tmp}/waybar-hidden-by-fullscreen"

# True if the active window of the focused workspace covers its whole output.
# (niri's IPC has no "is_fullscreen" field, so compare tile size to output size.)
is_fullscreen() {
    local ws wins outs
    ws=$(niri msg --json workspaces) || return 1
    wins=$(niri msg --json windows) || return 1
    outs=$(niri msg --json outputs) || return 1

    jq -n -e --argjson ws "$ws" --argjson wins "$wins" --argjson outs "$outs" '
        ($ws | map(select(.is_focused)) | first) as $w
        | ($wins | map(select(.id == $w.active_window_id)) | first) as $win
        | ($outs[$w.output // ""]) as $o
        | ($win != null and $o.logical != null)
          and ((($win.layout.tile_size[0] - $o.logical.width)  | fabs) < 1)
          and ((($win.layout.tile_size[1] - $o.logical.height) | fabs) < 1)
    ' >/dev/null 2>&1
}

fs=0
while read -r line; do
    # only react to events that can change the fullscreen state
    case $line in
        *WindowsChanged*|*WindowOpenedOrChanged*|*WindowClosed*|*WindowFocusChanged*|*WindowLayoutsChanged*|*WorkspaceActivated*|*WorkspaceActiveWindowChanged*) ;;
        *) continue ;;
    esac

    if is_fullscreen; then now=1; else now=0; fi

    if [ "$now" = 1 ] && [ "$fs" = 0 ]; then
        # entered fullscreen: hide the bar (and remember that we did it)
        if pgrep -x waybar >/dev/null; then
            pkill -x waybar && : > "$FLAG"
        fi
    elif [ "$now" = 0 ] && [ "$fs" = 1 ]; then
        # left fullscreen: restore the bar, but only if we were the ones who hid it
        if [ -e "$FLAG" ]; then
            rm -f "$FLAG"
            pgrep -x waybar >/dev/null || setsid -f "$LAUNCH" >/dev/null 2>&1
        fi
    fi
    fs=$now
done < <(niri msg --json event-stream)
