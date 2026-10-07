#!/bin/sh
# RG DS: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rgds/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rgds-pad2key rgds-touch rgds-lid rgds-lid-settings rgds-logout rgds-screenoff rgds-cheatsheet rgds-wallpaper rgds-brightness rgds-bar rgds-bar-sensor rgds-bar-settings rgds-scale rgds-rofi rgds-wireless rgds-rumble rgds-stick rgds-capture rgds-stick-swap rgds-stick-settings /usr/bin/
install -m 644 rgds-touch.service /etc/systemd/system/
install -m 644 rgds-lid-settings.desktop rgds-cheatsheet.desktop \
	rgds-wallpaper.desktop rgds-brightness.desktop \
	rgds-bar-settings.desktop rgds-scale.desktop rgds-wireless.desktop rgds-stick-settings.desktop /usr/share/applications/
install -m 644 49-rgds-touch.rules /etc/polkit-1/rules.d/
install -m 644 icons/*.svg /usr/share/icons/hicolor/scalable/apps/
gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true

f=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)/.config/rgds-scale/monitor.conf
[ -f "$f" ] && sed -i 's/^monitorrule=/monitor_rule=/' "$f"

# a short buzz when a charger is plugged in
install -m 644 99-rgds-rumble.rules /etc/udev/rules.d/
udevadm control --reload

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rgds-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl daemon-reload
systemctl disable --now rgds-touch
systemctl restart rgds-pad2key

# the sticks as a mouse.
# its settings file is the user's to write, so rgds-stick-settings and
# rgds-stick-swap need no password
[ -e /etc/rgds-stick.json ] || echo '{}' >/etc/rgds-stick.json
chown "${SUDO_USER:-root}" /etc/rgds-stick.json
chmod 644 /etc/rgds-stick.json
cat >/etc/systemd/system/rgds-stick.service <<'UNIT'
[Unit]
Description=RG DS sticks as a mouse

[Service]
ExecStart=/usr/bin/rgds-stick
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable rgds-stick
systemctl restart rgds-stick
