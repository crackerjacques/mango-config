# mango-config for Raspberry Pi

A [mango](https://github.com/mangowm/mango) Wayland desktop for the Raspberry
Pi (4, 400, 5, 500, CM5) running Ubuntu 26.04, with a keyboard and mouse, a
touchscreen, or both. Works on an HDMI monitor, the official Touch Display 2
and small SPI/DSI touch panels.

Based on [DreamMaoMao/mango-config](https://github.com/DreamMaoMao/mango-config).
The Anbernic handhelds have their own branches: `anbernic-rg-ds`,
`anbernic-rg-vita-pro`, `anbernic-rg-rotate`.

## Install

Run this as your normal user (not root) on the Pi:

```bash
sudo apt install git
git clone -b rpi https://github.com/crackerjacques/mango-config
bash mango-config/mangowm_setup.sh
```

It asks which input method to set up (none, Japanese, Chinese, Korean,
Vietnamese) and to confirm, then:

1. installs the build and runtime packages with apt
2. builds wlroots 0.20.2, scenefx 0.5, mango, foot 1.28 and mangobar from
   source into `/usr/local` (mango with `patches/`, see below)
3. builds wl-clip-persist, dimland and satty with cargo (slow)
4. clones this branch to `~/.config/mango` and installs the Nerd Fonts symbols
5. installs fcitx5 with the chosen input method, if any
6. installs the helpers in `rpi/` (`rpi/install.sh`)
7. optionally sets up SDDM to log you straight into mango

The build sources go in `mango-config/src`. At the end the setup offers to
delete them; once you are done, delete the whole `mango-config` folder. If a
step fails, re-run just that step and the ones after it, for example
`bash mango-config/mangowm_setup.sh foot extras`.
Steps: `deps wlroots scenefx mango foot extras rust config ime board autologin`.

To update later:

```bash
git -C ~/.config/mango pull
sudo sh ~/.config/mango/rpi/install.sh
mmsg dispatch reload_config
```

## Keys

| Keys | Action |
| --- | --- |
| Super (tap) | App menu |
| Super + F1 | Keyboard shortcuts (tap a row to run it) |
| Alt + Return | Terminal |
| Super + F2 | Files |
| Super + PgUp | On-screen keyboard |
| Alt + q | Close window |
| Alt + Tab | Switch window |
| Alt + arrows | Focus the window that way |
| Super + Shift + arrows | Swap the window with the one that way |
| Super + ←/→ | Previous / next desktop |
| Ctrl + Space | Input method (fcitx5) on / off |
| Super + Esc | Screen off - any key, mouse move or touch wakes it |
| Super + l | Lock the screen |
| POWER (Pi 5) | Power menu (screen off, suspend, reboot, shut down, log out); hold to power off |

The full list is in `bind.conf`; Super + F1 shows the ones above.

## Helpers (`rpi/`)

| File | What it does |
| --- | --- |
| `rpi-scale` | Display: scale and rotation of each connected screen, kept only if confirmed |
| `rpi-logout` | Touch-friendly power menu (power key, bar icon) |
| `rpi-screenoff` | Blanks every screen until the next input |
| `rpi-cheatsheet` | Keyboard shortcuts; tap a row to run it |
| `rpi-wallpaper` | Pick the wallpaper and its layout (fill, fit, stretch, center, tile) |
| `rpi-brightness` | Backlight slider for the official displays (an HDMI monitor has its own) |
| `rpi-wireless` | Wireless on/off (Airplane mode): Wi-Fi and Bluetooth off, or back as they were |
| `rpi-bar-settings` | mangobar theme, shape and contents |
| `rpi-bar`, `rpi-bar-sensor` | Start mangobar with those settings; sensor readings for it |
| `rpi-rofi` | Opens the app menu on the focused screen, closing one left open |
| `install.sh` | Puts the above in `/usr/bin` and leaves a short power-key press to mango |

## Display

Every screen starts at mango's defaults. Set the scale and rotation with
Display (`rpi-scale`), which writes `~/.config/rpi-scale/monitor.conf`. The
Touch Display 2 is portrait; turn it 90° for landscape.

## mango patch

`patches/mango-im-replay-no-rebind.patch` stops mango from running its
keybindings a second time on keys that fcitx5 hands back from its keyboard
grab. Without it, a replayed lone Super press/release looks like a bare
Super tap, so rofi pops up on Super + key shortcuts while fcitx5 runs.
