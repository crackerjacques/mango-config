#!/bin/sh
# RG DS: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rgds/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rgds-pad2key rgds-touch rgds-lid rgds-lid-settings rgds-logout rgds-screenoff rgds-cheatsheet rgds-wallpaper rgds-brightness rgds-bar rgds-bar-sensor rgds-bar-settings rgds-scale rgds-rofi /usr/bin/
install -m 644 rgds-touch.service /etc/systemd/system/
install -m 644 rgds-lid-settings.desktop rgds-cheatsheet.desktop \
	rgds-wallpaper.desktop rgds-brightness.desktop \
	rgds-bar-settings.desktop rgds-scale.desktop /usr/share/applications/
install -m 644 49-rgds-touch.rules /etc/polkit-1/rules.d/
# own icons in hicolor, which every icon theme falls back to
install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rgds-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

# rgds-touch grabs the real panels, so it must not run under X11: the mango
# session starts and stops it (autostart.sh / logout) instead of boot.
systemctl daemon-reload
systemctl disable --now rgds-touch
systemctl restart rgds-pad2key
