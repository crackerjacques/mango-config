#!/bin/sh
# RG Rotate: install the mango helpers system-wide.
# Run from anywhere: sudo sh ~/.config/mango/rotate/install.sh
set -e
cd "$(dirname "$0")"

install -m 755 rotate-pad2key rotate-lid rotate-lid-settings rotate-logout /usr/bin/
install -m 644 rotate-lid-settings.desktop /usr/share/applications/

mkdir -p /etc/systemd/logind.conf.d
cat >/etc/systemd/logind.conf.d/50-rotate-powerkey.conf <<'CONF'
[Login]
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
CONF
systemctl reload systemd-logind

systemctl restart rotate-pad2key
