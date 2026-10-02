#!/bin/sh
# RG DS: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rgds/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rgds-pad2key rgds-touch rgds-lid rgds-lid-settings rgds-logout /usr/bin/
install -m 644 rgds-touch.service /etc/systemd/system/
install -m 644 rgds-lid-settings.desktop /usr/share/applications/

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rgds-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl daemon-reload
systemctl enable rgds-touch
systemctl restart rgds-pad2key rgds-touch
