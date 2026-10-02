#!/bin/sh
# RG Vita Pro: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/vita/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 vita-pad2key vita-logout vita-screenoff vita-wallpaper vita-cheatsheet vita-brightness /usr/bin/
install -m 644 vita-wallpaper.desktop vita-cheatsheet.desktop vita-brightness.desktop \
	/usr/share/applications/
# own icons in hicolor, which every icon theme falls back to
install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-vita-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl restart vita-pad2key
