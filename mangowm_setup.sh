#!/bin/bash
# RG DS: build and set up mango on Ubuntu 26.04 from scratch.

set -eu

SRC=$HOME/src/mango-build
CONFIG_REPO=https://github.com/crackerjacques/mango-config.git
CONFIG_BRANCH=anbernic-rg-ds
JOBS=$(nproc)

say() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

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
		libasound2-dev libpam0g-dev \
		rofi xdg-desktop-portal-wlr swaybg cliphist wl-clipboard wlsunset \
		xfce-polkit sway-notification-center pamixer swayidle brightnessctl swayosd \
		wlr-randr grim slurp sox wvkbd fonts-font-awesome fonts-hack \
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
	fetch https://github.com/mangowm/mango.git mango
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

step_board() {
	say "RG DS helpers (pad2key, touch, power menu)"
	sudo sh "$HOME/.config/mango/rgds/install.sh"
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

ALL="deps wlroots scenefx mango foot extras rust config board autologin"

[ "$(id -u)" -ne 0 ] || { echo "run as the desktop user, not root" >&2; exit 1; }

cat <<EOF

  Anbernic RG-DS AutoSetup
  ========================
  Builds the mango Wayland compositor and its desktop pieces from source
  (wlroots, scenefx, mango, foot, mangobar, ...) into /usr/local, puts the
  RG DS mango config in ~/.config/mango and installs the RG DS helpers
  (gamepad keys, dual touchscreens, power menu).

  Steps to run: ${*:-$ALL}
  Sources go to $SRC. This takes a long time on the RG DS.

EOF
read -r -p "Proceed? (N/y) " answer </dev/tty
case "$answer" in
	[yY]*) ;;
	*) echo "aborted"; exit 0 ;;
esac

mkdir -p "$SRC"
for s in ${*:-$ALL}; do
	case " $ALL " in
		*" $s "*) "step_$s" ;;
		*) echo "unknown step: $s (steps: $ALL)" >&2; exit 1 ;;
	esac
done
say "done - log out and pick mango in the login screen"
