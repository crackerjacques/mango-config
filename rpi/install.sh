#!/bin/sh
# Raspberry Pi: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rpi/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rpi-logout rpi-screenoff rpi-wallpaper rpi-cheatsheet rpi-brightness rpi-bar rpi-bar-sensor rpi-bar-settings rpi-scale rpi-rofi rpi-wireless /usr/bin/
install -m 644 rpi-wallpaper.desktop rpi-cheatsheet.desktop rpi-brightness.desktop \
	rpi-bar-settings.desktop rpi-scale.desktop rpi-wireless.desktop \
	/usr/share/applications/
# own icons in hicolor, which every icon theme falls back to
install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

# the Pi 5 power button: a short press opens the power menu (bind.conf)
# instead of shutting down; holding it still powers off
mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rpi-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind
