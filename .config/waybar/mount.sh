 #!/usr/bin/bash
 
# 1. Find all USB-attached disks (any /dev/sdX, not just sdd)
usb_disks=$(lsblk -dnro NAME,TRAN 2>/dev/null | awk '$2=="usb" {print $1}')
 
# 2. Check if any USB disk (or one of its partitions) is mounted
mounted=0
for disk in $usb_disks; do
    if lsblk -nro MOUNTPOINTS "/dev/$disk" 2>/dev/null | grep -q .; then
        mounted=1
        break
    fi
done
 
if [ -n "$usb_disks" ]; then
 
    if [ "$mounted" -eq 1 ]; then
        # Mounted: Solid USB icon
        echo '{"text": " ", "tooltip": "USB Drive Mounted", "class": "mounted"}'
    else
        # Connected but Unmounted: Outline USB icon
        echo '{"text": "󱇰", "tooltip": "USB Drive Connected (Unmounted)", "class": "unmounted"}'
    fi
 
else
    # Disconnected: Hide module completely
    echo '{"text": ""}'
fi  

