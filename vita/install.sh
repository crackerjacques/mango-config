#!/bin/sh
# RG Vita Pro: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/vita/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 vita-pad2key vita-logout vita-screenoff vita-wallpaper vita-cheatsheet vita-brightness vita-bar vita-bar-sensor vita-bar-settings vita-scale vita-rofi vita-leds vita-leds-settings vita-wireless vita-rumble /usr/bin/
install -m 644 vita-wallpaper.desktop vita-cheatsheet.desktop vita-brightness.desktop \
	vita-bar-settings.desktop vita-scale.desktop vita-leds-settings.desktop vita-wireless.desktop \
	/usr/share/applications/
# own icons in hicolor, which every icon theme falls back to
install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

# mango renamed monitorrule to monitor_rule (October 2026): fix a scale saved
# by an older vita-scale, or mango stops at an unknown keyword
f=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)/.config/vita-scale/monitor.conf
[ -f "$f" ] && sed -i 's/^monitorrule=/monitor_rule=/' "$f"

# a short buzz when a charger is plugged in
install -m 644 99-vita-rumble.rules /etc/udev/rules.d/
udevadm control --reload

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-vita-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl restart vita-pad2key

# stick rings as a status light. Its settings file is the user's to write, so
# vita-leds-settings needs no password.
[ -e /etc/vita-leds.json ] || echo '{}' >/etc/vita-leds.json
chown "${SUDO_USER:-root}" /etc/vita-leds.json
chmod 644 /etc/vita-leds.json
cat >/etc/systemd/system/vita-leds.service <<'UNIT'
[Unit]
Description=RG Vita Pro stick rings as a status light

[Service]
ExecStart=/usr/bin/vita-leds
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable vita-leds
systemctl restart vita-leds
