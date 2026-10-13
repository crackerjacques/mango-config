#!/bin/sh
# Volume keys. swayosd-server shows the level and makes the change, but it can
# die (screen off and on, output changes, a PipeWire restart) and nothing
# starts it again - so start it here when it is gone, and if the client still
# fails, change the volume with pamixer without the on-screen level.

if ! pgrep -x swayosd-server >/dev/null; then
	swayosd-server >/dev/null 2>&1 &
	sleep 0.5
fi

case $1 in
up)	timeout 2 swayosd-client --output-volume 5 || pamixer -i 5 ;;
down)	timeout 2 swayosd-client --output-volume -5 || pamixer -d 5 ;;
mute)	timeout 2 swayosd-client --output-volume mute-toggle || pamixer -t ;;
esac
