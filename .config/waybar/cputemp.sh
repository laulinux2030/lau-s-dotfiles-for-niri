#!/usr/bin/env bash
# ~/.config/waybar/scripts/cputemp.sh

# Find the CPU sensor (AMD: k10temp/zenpower, Intel: coretemp)
for h in /sys/class/hwmon/hwmon*; do
    case "$(<"$h/name")" in
        k10temp|coretemp|zenpower) raw=$(<"$h/temp1_input"); break ;;
    esac
done

# GPU temperature (tooltip only)
gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
if [ -n "$gpu" ]; then gpu="${gpu}°C"; else gpu="N/A"; fi

# No CPU sensor found
if [ -z "$raw" ]; then
    printf '{"text":"N/A","alt":"low","tooltip":"CPU: N/A\\nGPU: %s"}\n' "$gpu"
    exit 0
fi

# Millidegrees -> degrees
t=$((raw / 1000))

# Pick the range (alt is the key into format-icons, class is for CSS)
if   [ "$t" -lt 55 ]; then alt=low
elif [ "$t" -lt 65 ]; then alt=mid
elif [ "$t" -lt 77 ]; then alt=high
else                       alt=critical
fi

printf '{"text":"%s°C","alt":"%s","class":"%s","tooltip":"CPU: %s°C\\nGPU: %s"}\n' "$t" "$alt" "$alt" "$t" "$gpu"
