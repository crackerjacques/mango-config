#!/bin/sh
# RG Rotate: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rotate/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rotate-pad2key rotate-lid rotate-lid-settings rotate-logout rotate-wallpaper rotate-cheatsheet rotate-brightness rotate-bar rotate-bar-sensor rotate-bar-settings rotate-scale rotate-rofi rotate-wireless rotate-rumble rotate-capture /usr/bin/
install -m 644 rotate-lid-settings.desktop rotate-wallpaper.desktop \
	rotate-cheatsheet.desktop rotate-brightness.desktop \
	rotate-bar-settings.desktop rotate-scale.desktop rotate-wireless.desktop /usr/share/applications/

install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

install -m 644 99-rotate-rumble.rules /etc/udev/rules.d/
udevadm control --reload

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rotate-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl restart rotate-pad2key
