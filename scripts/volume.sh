#!/bin/sh
# Volume keys.

if ! pgrep -x swayosd-server >/dev/null; then
	swayosd-server >/dev/null 2>&1 &
	sleep 0.5
fi

case $1 in
up)	timeout 2 swayosd-client --output-volume 5 || pamixer -i 5 ;;
down)	timeout 2 swayosd-client --output-volume -5 || pamixer -d 5 ;;
mute)	timeout 2 swayosd-client --output-volume mute-toggle || pamixer -t ;;
esac
