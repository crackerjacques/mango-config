# mango-config for Anbernic RG Vita Pro

A [mango](https://github.com/mangowm/mango) Wayland desktop for the Anbernic
RG Vita Pro (RK3576) running Armbian / Ubuntu 26.04, driven by the built-in
gamepad and touchscreen - no keyboard needed.

Based on [DreamMaoMao/mango-config](https://github.com/DreamMaoMao/mango-config).
Other handhelds have their own branch: `anbernic-rg-ds`, `anbernic-rg-rotate`.

## Install

Run this as your normal user (not root) on the device:

```bash
curl -LO https://raw.githubusercontent.com/crackerjacques/mango-config/anbernic-vita-pro/mangowm_setup.sh
bash mangowm_setup.sh
```

It asks which input method to set up (none, Japanese, Chinese, Korean,
Vietnamese) and to confirm, then:

1. installs the build and runtime packages with apt
2. builds wlroots 0.20.2, scenefx 0.5, mango, foot 1.28 and mangobar from
   source into `/usr/local` (mango with `patches/`, see below)
3. builds wl-clip-persist, dimland and satty with cargo (slow)
4. clones this branch to `~/.config/mango` and installs the Nerd Fonts symbols
5. installs fcitx5 with the chosen input method, if any
6. installs the Vita Pro helpers in `vita/` (`vita/install.sh`)
7. optionally sets up SDDM to log you straight into mango

Sources are kept in `~/src/mango-build`. If a step fails, re-run just that
step and the ones after it, for example `bash mangowm_setup.sh foot extras`.
Steps: `deps wlroots scenefx mango foot extras rust config ime board autologin`.

To update later:

```bash
git -C ~/.config/mango pull
sudo sh ~/.config/mango/vita/install.sh
mmsg dispatch reload_config
```

## Controls

| Button | Action |
| --- | --- |
| START (tap) | App menu |
| START (hold) + d-pad ←/→ | Previous / next desktop |
| L1 | On-screen keyboard |
| R1 | Terminal |
| L2 | Previous desktop |
| R2 | Controls cheat sheet (tap a row to run it) |
| SELECT | Screen off - any button or touch wakes it |
| HOME (one of the two) | Switch window |
| HOME (the other) | Input method (fcitx5) on / off |
| X | Close window |
| A / B | Enter / Esc |
| Y | Backspace |
| D-pad | Arrow keys |
| L3 / R3 | Shift+Tab / Tab |
| POWER | Power menu (screen off, suspend, reboot, shut down, log out); hold to power off |

The analog sticks are left alone and always work as a gamepad.
"Toggle Pad-as-Keyboard" in the app menu turns the button remap off for games.

## Helpers (`vita/`)

| File | What it does |
| --- | --- |
| `vita-pad2key` | Gamepad buttons → keys; replaces the board package's version |
| `vita-logout` | Touch-friendly power menu (power key, bar icon) |
| `vita-screenoff` | Blanks the panel until the next input |
| `vita-cheatsheet` | Controls list; tap a row to run it |
| `vita-wallpaper` | Pick the wallpaper and its layout (fill, fit, stretch, center, tile) |
| `vita-brightness` | Screen brightness slider (there are no brightness keys) |
| `vita-bar-settings` | mangobar theme, shape and contents, for the panel and an external screen |
| `vita-bar`, `vita-bar-sensor` | Start mangobar with those settings; sensor readings for it |
| `install.sh` | Puts the above in `/usr/bin` and leaves a short power-key press to mango |

## Display

The panel is mounted portrait and mango does not read the DRM
panel-orientation property, so `monitor.conf` turns it with `rr:1` and scales
it with `scale:1.5`. If the picture is upside down, use `rr:3`; change `scale`
to taste.

## mango patch

`patches/mango-im-replay-no-rebind.patch` stops mango from running its
keybindings a second time on keys that fcitx5 hands back from its keyboard
grab. Without it, a replayed lone Super press/release looks like a bare
Super tap, so rofi pops up on every START + button chord while fcitx5 runs.
