# Maintainer: simonjones49
pkgname=mi-shell-git
pkgver=r31.678abcd
pkgrel=1
pkgdesc="Vertical Quickshell bar for niri with power and calendar utilities"
arch=('any')
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
)

optdepends=(
  'bluetui: for the Bluetooth manager UI'
  'nmtui: for the Network manager UI'
  'librewolf: for the browser shortcuts'
  'playerctl: recommended for better MPRIS control'
  'vdirsyncer: sync local khal calendar with Google/CalDAV'
  'pcmanfm: Recommended file manager'
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

package() {
  local _src="${srcdir}/${pkgname}"

  # 1. Install to /etc/xdg/quickshell/mi-shell for fallback config
  install -d "${pkgdir}/etc/xdg/quickshell/mi-shell"
  cp -r "${_src}/"* "${pkgdir}/etc/xdg/quickshell/mi-shell/"

  # 2. Install scripts to /usr/bin using -D to ensure path creation
  install -Dm755 "${_src}/scripts/mi-power" "${pkgdir}/usr/bin/mi-power"
  install -Dm755 "${_src}/scripts/mi-caffeine" "${pkgdir}/usr/bin/mi-caffeine"
  install -Dm755 "${_src}/scripts/mi-caffeine-flag.sh" "${pkgdir}/usr/bin/mi-caffeine-flag.sh"

  # 3. Install example config for user home directory setup
  install -Dm644 "${_src}/mi-shell.kdl" "${pkgdir}/usr/share/mi-shell/mi-shell.kdl.example"

  # 4. Cleanup system config folder (Remove build-only files)
  rm -rf "${pkgdir}/etc/xdg/quickshell/mi-shell/scripts"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/PKGBUILD"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/mi-shell.install"
}
