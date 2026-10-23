#!/usr/bin/env bash
# mountalt.sh - rofi USB menu in script mode: mount / unmount / power off / unmount + power off
# One persistent rofi window: device list -> action list, no flicker in between.
# Requires: rofi (>= 1.7), udisks2 (udisksctl), util-linux (lsblk, findmnt), libnotify (notify-send)
#
# Usage: just run this script (e.g. from a keybind). It starts rofi in script mode
# with itself as the backend; rofi then calls it again for every step.
#
# Debug log (delete the log() calls once everything works):
#   cat "${XDG_RUNTIME_DIR:-/tmp}/mountalt.log"
 
THEME="$HOME/.config/rofi/mount.rasi"
LOG="${XDG_RUNTIME_DIR:-/tmp}/mountalt.log"
 
ICON_MOUNTED=""
ICON_UNMOUNTED=""
ICON_MOUNT=""
ICON_UNMOUNT=""
ICON_KILL=""
ICON_UNMOUNT_KILL=""
 
notify() { notify-send -a "USB" "$1" "$2"; }
log()    { printf '%s %s\n' "$(date +%T)" "$*" >> "$LOG"; }
 
# does any partition of this physical disk ($1) have a mountpoint?
disk_has_mounts() {
    local d
    while read -r d; do
        findmnt -rn -S "$d" >/dev/null && return 0
    done < <(lsblk -lnpo KNAME "$1")
    return 1
}
 
unmount_all() {   # $1 = physical disk
    local d out rc=0
    while read -r d; do
        if findmnt -rn -S "$d" >/dev/null; then
            out=$(udisksctl unmount -b "$d" 2>&1) || { log "unmount $d failed: $out"; notify "Unmount failed: $d" "$out"; rc=1; }
        fi
    done < <(lsblk -lnpo KNAME "$1")
    return $rc
}
 
# filter for the current lsblk row (after eval): hot-pluggable, has a filesystem, not LUKS
is_usb_fs() {
    [[ "$HOTPLUG" == "1" && -n "$FSTYPE" && "$FSTYPE" != "crypto_LUKS" ]]
}
 
# is at least one such drive connected? (checked before rofi is opened)
has_devices() {
    local line HOTPLUG FSTYPE
    while IFS= read -r line; do
        eval "$line"
        is_usb_fs && return 0
    done < <(lsblk -P -p -o KNAME,HOTPLUG,FSTYPE)
    return 1
}
 
# ---- phase 1: device list ----
# Every row carries "KNAME|disk" as its hidden info value (read back as $ROFI_INFO).
show_devices() {
    local line disk name mp icon used info i
    local labels=() infos=()   # kept apart: a NUL byte (needed by rofi) can't be stored in a bash variable
 
    while IFS= read -r line; do
        eval "$line"   # lsblk -P output is shell-safe (KEY="value", special chars hex-escaped)
        is_usb_fs || continue
 
        if [[ "$TYPE" == "part" ]]; then
            disk="$PKNAME"
        else
            disk="$KNAME"
        fi
 
        name=$(printf '%b' "${LABEL:-$MODEL}")
        mp=$(printf '%b' "$MOUNTPOINT")
        if [[ -n "$mp" ]]; then
            icon="$ICON_MOUNTED"
            used=$(df --output=pcent "$mp" 2>/dev/null | tail -n1 | tr -d ' ')
            info="$SIZE, ${used:-?}"
        else
            icon="$ICON_UNMOUNTED"
            info="$SIZE"
        fi
 
        labels+=("$icon  ${name:-unnamed}  ($info)")
        infos+=("$KNAME|$disk")
    done < <(lsblk -P -p -o KNAME,PKNAME,TYPE,HOTPLUG,SIZE,LABEL,FSTYPE,MOUNTPOINT,MODEL)
 
    # header options first, then the rows
    printf '\0prompt\x1fUSB drive\n\0no-custom\x1ftrue\n'
    if [[ ${#labels[@]} -eq 0 ]]; then
        printf '\0message\x1fNothing hot-pluggable with a filesystem is connected.\n'
        printf 'No USB drives found\0nonselectable\x1ftrue\n'
        return
    fi
    for i in "${!labels[@]}"; do
        printf '%s\0info\x1f%s\n' "${labels[$i]}" "${infos[$i]}"
    done
}
 
# ---- phase 2: action list for the chosen device ($1 = "KNAME|disk") ----
# Every action row carries "action|KNAME|disk", so nothing has to be remembered between calls.
show_actions() {
    local dev disk
    IFS='|' read -r dev disk <<<"$1"
 
    printf '\0prompt\x1f%s\n\0no-custom\x1ftrue\n' "$dev"
 
    if findmnt -rn -S "$dev" >/dev/null; then
        printf '%s  Unmount\0info\x1funmount|%s\n' "$ICON_UNMOUNT" "$1"
    else
        printf '%s  Mount\0info\x1fmount|%s\n' "$ICON_MOUNT" "$1"
    fi
 
    if disk_has_mounts "$disk"; then
        printf '%s  Unmount + Kill\0info\x1funmount-kill|%s\n' "$ICON_UNMOUNT_KILL" "$1"
    else
        printf '%s  Kill\0info\x1fkill|%s\n' "$ICON_KILL" "$1"
    fi
}
 
# ---- the actual work ----
run_action() {   # $1 = action, $2 = device, $3 = physical disk
    local action="$1" dev="$2" disk="$3" out
    log "run: action=$action dev=$dev disk=$disk"
    case "$action" in
        mount)
            out=$(udisksctl mount -b "$dev" 2>&1) \
                && { log "mounted: $out"; notify "Mounted" "$out"; } \
                || { log "mount failed: $out"; notify "Mount failed" "$out"; }
            ;;
        unmount)
            out=$(udisksctl unmount -b "$dev" 2>&1) \
                && { log "unmounted $dev"; notify "Unmounted" "$dev"; } \
                || { log "unmount failed: $out"; notify "Unmount failed" "$out"; }
            ;;
        kill)
            sync
            out=$(udisksctl power-off -b "$disk" 2>&1) \
                && { log "powered off $disk"; notify "Powered off" "$disk - safe to remove"; } \
                || { log "power off failed: $out"; notify "Power off failed" "$out"; }
            ;;
        unmount-kill)
            if unmount_all "$disk"; then
                sync
                out=$(udisksctl power-off -b "$disk" 2>&1) \
                    && { log "unmounted and powered off $disk"; notify "Safe to remove" "$disk unmounted and powered off"; } \
                    || { log "power off failed: $out"; notify "Power off failed" "$out"; }
            fi
            ;;
        *)
            log "unknown action: $action"
            ;;
    esac
}
 
# ---- dispatch ----
 
# started by hand / keybind: open rofi with this script as its mode
if [[ -z "${ROFI_RETV:-}" ]]; then
    if ! has_devices; then
        notify "No USB drives found" "Nothing hot-pluggable with a filesystem is connected."
        exit 0
    fi
    exec rofi -theme "$THEME" -i -show usb -modi "usb:$(realpath "$0")"
fi
 
# called by rofi
log "rofi call: RETV=$ROFI_RETV INFO=${ROFI_INFO:-} arg=${1:-}"
case "$ROFI_RETV" in
    0)  # window just opened
        show_devices
        ;;
    1)  # an entry was selected
        [[ -n "${ROFI_INFO:-}" ]] || exit 0
        IFS='|' read -r f1 f2 f3 <<<"$ROFI_INFO"
        if [[ -z "$f3" ]]; then
            show_actions "$ROFI_INFO"                     # "KNAME|disk": device picked -> action list
        else
            run_action "$f1" "$f2" "$f3" >/dev/null 2>&1  # "action|KNAME|disk": do it; no output = rofi closes
        fi
        ;;
esac

