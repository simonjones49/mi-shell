# Maintainer: simonjones49
pkgname=mi-shell-git
pkgver=r31.678abcd
pkgrel=1
pkgdesc="Vertical Quickshell bar for niri with power and calendar utilities"
arch=('any')
url="https://github.com/simonjones49/mi-shell"
license=('GPL')
install=mi-shell.install

depends=(
  'quickshell'
  'qt6-5compat'
  'qt6-svg'
  'niri'
  'swww'
  'swayidle'
  'swaylock'
  'blueman'
  'khal'
  'brightnessctl'
  'networkmanager'
  'procps-ng'
  'libnotify'
  'pipewire'
  'kitty'
  'polkit-gnome'
)
optdepends=(
  'vdirsyncer: Optional: Only needed if you want to sync your local khal calendar with Google/CalDAV'
  'dolphin: Recommended file manager'
  'kate: Recommended text editor'
  'floorp: Recommended web browser for bar shortcuts'
  'mpv: Recommended media player'
  'nerd-fonts-git: fonts used in calendar'
)
makedepends=('git')

source=("${pkgname}::git+${url}.git")
sha256sums=('SKIP')

pkgver() {
  cd "${srcdir}/${pkgname}"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  # 1. Install to /etc/xdg/quickshell/mi-shell
  # This allows Quickshell to find it via XDG_CONFIG_DIRS fallback
  install -d "${pkgdir}/etc/xdg/quickshell/mi-shell"
  cp -r "${srcdir}/${pkgname}/"* "${pkgdir}/etc/xdg/quickshell/mi-shell/"

  # 2. Install scripts to /usr/bin
  install -d "${pkgdir}/usr/bin"
  install -m755 "${srcdir}/${pkgname}/scripts/mi-power" "${pkgdir}/usr/bin/mi-power"
  install -m755 "${srcdir}/${pkgname}/scripts/mi-sync" "${pkgdir}/usr/bin/mi-sync"

  # 3. Clean up the config folder
  rm -rf "${pkgdir}/etc/xdg/quickshell/mi-shell/scripts"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/PKGBUILD"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/mi-shell.install"
}
