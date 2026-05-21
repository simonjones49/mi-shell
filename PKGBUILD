# Maintainer: simonjones49
pkgname=mi-shell-git
pkgver=r31.678abcd
pkgrel=1
pkgdesc="Vertical Quickshell bar for niri with basic utilities"
arch=("x86_64")
url="https://github.com/simonjones49/mi-shell"
license=('MIT')
install=mi-shell.install

depends=(
  'quickshell-git'
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
)

optdepends=(
  'bluetui: for the Bluetooth manager UI'
  'nmtui: for the Network manager UI'
  'aerc: a TUI email client'
  'librewolf: for the browser shortcuts'
  'playerctl: recommended for better MPRIS control'
  'vdirsyncer: sync local khal calendar with Google/CalDAV'
  'dolphin: Recommended file manager'
  'kate: Recommended text editor'
  'mpv: Recommended media player'
)

makedepends=('git')
source=("${pkgname}::git+${url}.git")
sha256sums=('SKIP')

pkgver() {
  cd "${srcdir}/${pkgname}"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
  # Note: Use the variable defined in source, which is ${pkgname}
  cd "${srcdir}/${pkgname}"

  # Remove the .sh extension from the Bar.qml file for the system installation
  # We use the backslash to escape the dot so it's a literal match
  sed -i 's/exec: "librewolf\.sh"/exec: "librewolf"/g' bar/Bar.qml
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

  # Add setup script directly from your repository's scripts folder
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
