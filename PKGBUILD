# Maintainer: simonjones49
pkgname=mi-shell-git
pkgver=r167.8980b6a
pkgrel=1
pkgdesc="Vertical Quickshell bar for niri with basic utilities"
arch=("x86_64")
url="https://codeberg.org/simonjones49/mi-shell"
license=('MIT')
install=mi-shell.install

depends=(
  # 'quickshell-git'
  'qt6-wayland'
  'qt6-svg'
  'niri'
  'polkit-gnome'
  'swaybg'
  'swayidle'
  'swaylock'
  'libnotify'
  'pipewire'
  'brightnessctl'
  'khal'
  'networkmanager'
  'kitty'
  'udisks2'
  'ttf-jetbrains-mono-nerd'
  'network-manager-applet'
  'blueman'
  'dolphin'
  'pavucontrol'
  'qutebrowser'
  'playerctl'
  'kate'
  'mpv'
  'mpv-mpris'
  'python-keyring'
  'xwayland-satellite'
)

optdepends=(
  'aerc: a TUI email client'
  'vdirsyncer: sync local khal calendar with Google/CalDAV'
  'musikcube: Flawless music player with album art MPRIS connection'
  'keepassxc: A system keyring manager'
)

makedepends=('git')
source=("${pkgname}::git+${url}.git")
sha256sums=('SKIP')

pkgver() {
  cd "${srcdir}/${pkgname}"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
  cd "${srcdir}/${pkgname}"

  # 1. Clear the qutebrowser.sh extension
  sed -i 's/exec: "qutebrowser\.sh"/exec: "qutebrowser"/g' bar/Bar.qml

  # 2. Delete the entire --basedir argument from the original string
  sed -i 's@--basedir \$HOME/\.local/share/qutebrowser/profiles/main @@g' themeSwitcher/Theme.qml

  # 3. Change the remaining path and drop the extra '/config/' subfolder entirely
  sed -i 's@\.local/share/qutebrowser/profiles/main/config/@\.config/qutebrowser/@g' themeSwitcher/Theme.qml
}

package() {
  local _src="${srcdir}/${pkgname}"

  # 1. Install to /etc/xdg/quickshell/mi-shell for fallback config
  install -d "${pkgdir}/etc/xdg/quickshell/mi-shell"
  cp -r "${_src}/"* "${pkgdir}/etc/xdg/quickshell/mi-shell/"

  # 2. Install scripts to /usr/bin
  install -Dm755 "${_src}/scripts/mi-power" "${pkgdir}/usr/bin/mi-power"
  install -Dm755 "${_src}/scripts/mi-caffeine" "${pkgdir}/usr/bin/mi-caffeine"
  install -Dm755 "${_src}/scripts/mi-caffeine-flag.sh" "${pkgdir}/usr/bin/mi-caffeine-flag.sh"
  install -Dm755 "${_src}/scripts/mi-shell-setup" "${pkgdir}/usr/bin/mi-shell-setup"

# 3. Install system assets & example config
  install -Dm644 "${_src}/mi-shell.kdl" "${pkgdir}/usr/share/mi-shell/mi-shell.kdl.example"
  install -Dm644 "${_src}/mi-wall.png" "${pkgdir}/usr/share/mi-shell/mi-wall.png"

  # 4. Cleanup (Keep the system files lean)
  rm -rf "${pkgdir}/etc/xdg/quickshell/mi-shell/scripts"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/PKGBUILD"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/mi-shell.install"
  rm -rf "${pkgdir}/etc/xdg/quickshell/mi-shell/.git"
}
