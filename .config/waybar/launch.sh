
#!/usr/bin/env bash

# Beende bereits laufende Waybar-Instanzen, um Duplikate zu vermeiden
killall -q waybar

# Starte Waybar und leite den Output optional in /dev/null um
waybar &
