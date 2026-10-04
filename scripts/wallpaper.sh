#!/bin/sh
# Raspberry Pi: the wallpaper. rpi-wallpaper (the "Wallpaper" app) keeps the
# chosen image and display mode in ~/.config/rpi-wallpaper; without them
# the default wallpaper/wallpaper.png is used, zoomed to fill.
u=${XDG_CONFIG_HOME:-$HOME/.config}/rpi-wallpaper
img=$u/screen; [ -e "$img" ] || img=~/.config/mango/wallpaper/wallpaper.png
mode=$(cat "$u/screen.mode" 2>/dev/null); : "${mode:=fill}"
pkill -x swaybg
exec swaybg -i "$img" -m "$mode"
