#!/bin/sh
# RG Rotate: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rotate/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rotate-pad2key rotate-lid rotate-lid-settings rotate-logout rotate-wallpaper rotate-cheatsheet rotate-brightness rotate-bar rotate-bar-sensor rotate-bar-settings /usr/bin/
install -m 644 rotate-lid-settings.desktop rotate-wallpaper.desktop \
	rotate-cheatsheet.desktop rotate-brightness.desktop \
	rotate-bar-settings.desktop /usr/share/applications/
# own icons in hicolor, which every icon theme falls back to
install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rotate-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl restart rotate-pad2key
