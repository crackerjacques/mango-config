#!/bin/sh
# RG DS: one wallpaper per screen. rgds-wallpaper (the "Wallpaper" app) keeps
# the chosen images and display modes in ~/.config/rgds-wallpaper; without
# them the defaults here in wallpaper/top.png (DSI-2) and wallpaper/bottom.png
# (DSI-1) are used, zoomed to fill.
w=~/.config/mango/wallpaper
u=${XDG_CONFIG_HOME:-$HOME/.config}/rgds-wallpaper
top=$u/top;       [ -e "$top" ] || top=$w/top.png
bottom=$u/bottom; [ -e "$bottom" ] || bottom=$w/bottom.png
tmode=$(cat "$u/top.mode" 2>/dev/null);    : "${tmode:=fill}"
bmode=$(cat "$u/bottom.mode" 2>/dev/null); : "${bmode:=fill}"
pkill -x swaybg
exec swaybg -o DSI-2 -i "$top" -m "$tmode" -o DSI-1 -i "$bottom" -m "$bmode"
