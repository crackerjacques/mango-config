#!/bin/bash
# RG Rotate: build and set up mango on Debian forky (testing) or sid
# from scratch. For Ubuntu 26.04 use mangowm_setup.sh.

set -eu


HERE=$(cd "$(dirname "$0")" && pwd)
if [ -e "$HERE/.git" ] && [ -f "$HERE/bind.conf" ] && [ "$HERE" != "$HOME/.config/mango" ]; then
	SRC=$HERE/src
else
	SRC=${XDG_CACHE_HOME:-$HOME/.cache}/mango-build
fi
CONFIG_REPO=https://github.com/crackerjacques/mango-config.git
CONFIG_BRANCH=anbernic-rg-rotate
RAW=https://raw.githubusercontent.com/crackerjacques/mango-config/$CONFIG_BRANCH
JOBS=$(nproc)

say() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }


check_os() {
	. /etc/os-release
	if [ "${ID:-}" != debian ]; then
		echo "This script is for Debian. On Ubuntu use mangowm_setup.sh." >&2
		exit 1
	fi
	if [ -n "${VERSION_ID:-}" ]; then
		echo "Debian $VERSION_ID ($VERSION_CODENAME) is not supported." >&2
		echo "Trixie and older lack the wayland, libdrm and xkbcommon that" >&2
		echo "wlroots 0.20 needs. Use Debian forky (testing) or sid." >&2
		exit 1
	fi
}

fetch() {
	if [ -d "$SRC/$2/.git" ]; then
		git -C "$SRC/$2" fetch --tags -q
	else
		git clone -q "$1" "$SRC/$2"
	fi
	[ -n "${3:-}" ] && git -C "$SRC/$2" checkout -q "$3"
	# a tag leaves HEAD detached and needs no pull; a branch does
	if git -C "$SRC/$2" symbolic-ref -q HEAD >/dev/null; then
		git -C "$SRC/$2" pull -q --ff-only
	fi
}

# meson build + install of $SRC/<dir> into /usr/local
build() {
	local dir=$SRC/$1; shift
	rm -rf "$dir/build"
	meson setup "$dir/build" "$dir" --prefix=/usr/local --buildtype=release "$@"
	ninja -C "$dir/build" -j "$JOBS"
	sudo ninja -C "$dir/build" install
	sudo ldconfig
}

step_deps() {
	say "apt packages"
	sudo apt-get update
	sudo apt-get install -y \
		build-essential meson ninja-build pkg-config git curl xz-utils hwdata scdoc \
		libwayland-dev wayland-protocols libinput-dev libdrm-dev libgbm-dev \
		libegl-dev libgles-dev libxkbcommon-dev libpixman-1-dev \
		libdisplay-info-dev libliftoff-dev libseat-dev libudev-dev \
		libpcre2-dev libpango1.0-dev libcjson-dev \
		xwayland libxcb1-dev libxcb-composite0-dev libxcb-icccm4-dev \
		libxcb-res0-dev libxcb-xfixes0-dev libxcb-render0-dev libxcb-ewmh-dev \
		libxcb-errors-dev libxcb-randr0-dev \
		libfcft-dev libtllist-dev libutf8proc-dev libfontconfig-dev ncurses-bin \
		libcairo2-dev libpulse-dev libsystemd-dev libgdk-pixbuf-2.0-dev systemd-dev \
		libasound2-dev libpam0g-dev pavucontrol pulseaudio-utils\
		rofi xdg-desktop-portal-wlr swaybg cliphist wl-clipboard wlsunset \
		xfce-polkit polkitd sway-notification-center pipewire-audio pamixer swayidle brightnessctl swayosd rfkill libnotify-bin \
		wlr-randr grim slurp sox wvkbd wlogout wf-recorder fonts-font-awesome fonts-hack fonts-noto-core fonts-noto-color-emoji \
		blueman network-manager-applet x11-xserver-utils gtk-update-icon-cache \
		python3-gi gir1.2-gtk-4.0 python3-evdev thunar breeze-icon-theme
}

step_wlroots() {
	say "wlroots 0.20.2"
	fetch https://gitlab.freedesktop.org/wlroots/wlroots.git wlroots 0.20.2
	build wlroots -Drenderers=gles2 -Dbackends=drm,libinput -Dxwayland=enabled -Dexamples=false
}

step_scenefx() {
	say "scenefx 0.5"
	fetch https://github.com/wlrfx/scenefx.git scenefx 0.5
	build scenefx
}

step_mango() {
	say "mango"
	# drop the patch applied by an earlier run so the pull can fast-forward
	[ -d "$SRC/mango/.git" ] && git -C "$SRC/mango" reset -q --hard
	fetch https://github.com/mangowm/mango.git mango
	# keys fcitx5 hands back from its keyboard grab must not hit the
	# keybindings a second time (opened rofi on every START chord)
	curl -fsSL -o "$SRC/mango-im-replay-no-rebind.patch" \
		"$RAW/patches/mango-im-replay-no-rebind.patch"
	git -C "$SRC/mango" apply "$SRC/mango-im-replay-no-rebind.patch"
	build mango
	# the session file lands in /usr/local/share; make sure login screens that
	# only look in /usr/share see it too
	sudo mkdir -p /usr/share/wayland-sessions
	sudo ln -sf /usr/local/share/wayland-sessions/mango.desktop /usr/share/wayland-sessions/
}

step_foot() {
	say "foot 1.28.0"
	fetch https://codeberg.org/dnkl/foot.git foot 1.28.0
	build foot
}

step_extras() {
	say "mangobar, sway-audio-idle-inhibit, swaylock-effects"
	fetch https://github.com/crackerjacques/mangobar.git mangobar anbernic-rg-rotate
	build mangobar
	fetch https://github.com/ErikReider/SwayAudioIdleInhibit.git SwayAudioIdleInhibit
	build SwayAudioIdleInhibit
	fetch https://github.com/jirutka/swaylock-effects.git swaylock-effects
	build swaylock-effects
}

step_rust() {
	say "rust tools (slow on this board)"
	sudo apt-get install -y rustup libgtk-4-dev libadwaita-1-dev libepoxy-dev
	rustup default stable
	cargo install --git https://github.com/Linus789/wl-clip-persist
	cargo install --git https://github.com/keifufu/dimland
	cargo install satty --locked
	sudo install -m 755 ~/.cargo/bin/wl-clip-persist ~/.cargo/bin/dimland \
		~/.cargo/bin/satty /usr/local/bin/
}

step_config() {
	say "mango config ($CONFIG_BRANCH) and fonts"
	if [ -d "$HOME/.config/mango/.git" ]; then
		git -C "$HOME/.config/mango" pull -q --ff-only
	else
		[ -e "$HOME/.config/mango" ] && mv "$HOME/.config/mango" "$HOME/.config/mango.bak.$(date +%s)"
		git clone -q -b "$CONFIG_BRANCH" "$CONFIG_REPO" "$HOME/.config/mango"
	fi
	mkdir -p "$HOME/.config/foot"
	cp "$HOME/.config/mango/foot/foot.ini" "$HOME/.config/foot/foot.ini"

	local fonts=$HOME/.local/share/fonts/NerdFontsSymbolsOnly
	if [ ! -d "$fonts" ]; then
		mkdir -p "$fonts"
		curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz |
			tar xJ -C "$fonts"
		fc-cache -f
	fi
}

# fcitx5 engine picked at the start (choose_ime) and the package that has it
IME=""
IME_PKG=""

choose_ime() {
	cat <<EOF
  Input method (fcitx5) for typing other languages:
    0) none
    1) Japanese             日本語      Mozc
    2) Chinese, Simplified  简体中文    Pinyin
    3) Chinese, Traditional 繁體中文    Chewing
    4) Korean               한국어      Hangul
    5) Vietnamese           Tiếng Việt  Unikey

EOF
	read -r -p "Choose [0-5] (0): " n </dev/tty
	case "$n" in
		1) IME=mozc;    IME_PKG=fcitx5-mozc ;;
		2) IME=pinyin;  IME_PKG=fcitx5-chinese-addons ;;
		3) IME=chewing; IME_PKG=fcitx5-chewing ;;
		4) IME=hangul;  IME_PKG=fcitx5-hangul ;;
		5) IME=unikey;  IME_PKG=fcitx5-unikey ;;
		*) IME="" ;;
	esac
}

step_ime() {
	if [ -z "$IME" ]; then
		say "input method: none"
		return 0
	fi
	say "input method: fcitx5 + $IME"
	# testing drops packages for a while now and then (fcitx5-mozc on arm64)
	if ! apt-cache show "$IME_PKG" >/dev/null 2>&1; then
		echo "$IME_PKG is not in this Debian release right now; skipping the input method."
		echo "Once it is back, run: bash mangowm_setup_debian.sh ime"
		return 0
	fi
	sudo apt-get install -y fcitx5 fcitx5-config-qt fonts-noto-cjk "$IME_PKG"

	# fcitx5 only offers what is in its input method group, and its settings
	# window does not fit these screens - so write the group here. fcitx5
	# rewrites this file when it exits, so make sure it is not running.
	fcitx5-remote -e 2>/dev/null || true
	for _ in 1 2 3 4 5 6 7 8 9 10; do
		pgrep -x fcitx5 >/dev/null || break
		sleep 0.3
	done
	local profile=$HOME/.config/fcitx5/profile
	mkdir -p "${profile%/*}"
	cat >"$profile" <<EOF
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=$IME

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=$IME
Layout=

[GroupOrder]
0=Default
EOF
	echo "fcitx5 starts with mango; START + d-pad up switches the input method on and off."
}

step_board() {
	say "RG Rotate helpers (pad2key, lid, power menu)"
	sudo sh "$HOME/.config/mango/rotate/install.sh"
}

step_autologin() {
	say "automatic login"
	read -r -p "Log $USER straight into mango at boot (SDDM autologin)? (N/y) " answer </dev/tty
	case "$answer" in
		[yY]*) ;;
		*) echo "skipped"; return 0 ;;
	esac
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y sddm
	echo /usr/bin/sddm | sudo tee /etc/X11/default-display-manager >/dev/null
	sudo systemctl enable --force sddm
	sudo mkdir -p /etc/sddm.conf.d
	sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null <<CONF
[Autologin]
User=$USER
Session=mango
CONF
	echo "SDDM now logs $USER into mango. To change or undo this, edit"
	echo "/etc/sddm.conf.d/autologin.conf (delete it to get the login screen back)."
}

# Offered at the end. Kept, a re-run of one step only fetches what changed,
# and "sudo ninja -C <dir>/build uninstall" can take a piece out again.
cleanup() {
	[ -d "$SRC" ] || return 0
	echo
	echo "Build sources in $SRC take $(du -sh "$SRC" | cut -f1)."
	echo "Keeping them makes re-running a step faster and lets you uninstall."
	read -r -p "Delete them? (N/y) " answer </dev/tty
	case "$answer" in
		[yY]*)
			# "sudo ninja install" leaves root-owned files in the build dirs
			rm -rf "$SRC" 2>/dev/null || sudo rm -rf "$SRC"
			echo "deleted" ;;
		*) echo "kept" ;;
	esac
}

ALL="deps wlroots scenefx mango foot extras rust config ime board autologin"

[ "$(id -u)" -ne 0 ] || { echo "run as the desktop user, not root" >&2; exit 1; }
check_os

cat <<EOF

  Anbernic RG Rotate AutoSetup (Debian)
  =====================================

  For Debian forky (testing) and sid only.
  Debian 13 (trixie) is NOT supported.

  Builds the mango Wayland compositor and its desktop pieces from source
  (wlroots, scenefx, mango, foot, mangobar, ...) into /usr/local, puts the
  RG Rotate mango config in ~/.config/mango and installs the RG Rotate
  helpers (gamepad keys, lid settings, power menu).

  Steps to run: ${*:-$ALL}
  Sources go to $SRC. This takes a long time on the RG Rotate.

EOF
case " ${*:-$ALL} " in
	*" ime "*) choose_ime; echo ;;
esac
read -r -p "Proceed? (N/y) " answer </dev/tty
case "$answer" in
	[yY]*) ;;
	*) echo "aborted"; exit 0 ;;
esac

# older versions built in ~/src/mango-build
if [ -d "$HOME/src/mango-build" ] && [ ! -e "$SRC" ]; then
	mkdir -p "${SRC%/*}"
	mv "$HOME/src/mango-build" "$SRC"
	rmdir "$HOME/src" 2>/dev/null || true
fi
mkdir -p "$SRC"
for s in ${*:-$ALL}; do
	case " $ALL " in
		*" $s "*) "step_$s" ;;
		*) echo "unknown step: $s (steps: $ALL)" >&2; exit 1 ;;
	esac
done
cleanup
say "done - log out and pick mango in the login screen"
