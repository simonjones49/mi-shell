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
  'ttf-nerd-fonts-symbols'
  'procps-ng'
  'libnotify'
  'bash'
  'pipewire'
  'kitty'
  'wayland-idle-inhibitor-git: Required for mi-power script'

)
optdepends=(
  'vdirsyncer: Optional: Only needed if you want to sync your local khal calendar with Google/CalDAV'
  'dolphin: Recommended file manager'
  'kate: Recommended text editor'
  'floorp: Recommended web browser for bar shortcuts'
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
  # 1. Install to /etc/xdg instead of /usr/share
  install -d "${pkgdir}/etc/xdg/quickshell/mi-shell"
  cp -r "${srcdir}/${pkgname}/"* "${pkgdir}/etc/xdg/quickshell/mi-shell/"

  # 2. Update your 'mi-shell' wrapper to point here too
  install -d "${pkgdir}/usr/bin"
  cat <<EOF > "${pkgdir}/usr/bin/mi-shell"
#!/bin/sh
mkdir -p "\$HOME/.config/quickshell/mi-shell"
exec quickshell -c mi-shell "\$@"
EOF
  chmod +x "${pkgdir}/usr/bin/mi-shell"

  # Install your scripts
  install -m755 "${srcdir}/${pkgname}/scripts/mi-power" "${pkgdir}/usr/bin/mi-power"
  install -m755 "${srcdir}/${pkgname}/scripts/mi-sync" "${pkgdir}/usr/bin/mi-sync"
  install -m755 "${srcdir}/${pkgname}/scripts/mi-idle" "${pkgdir}/usr/bin/mi-idle"


  # 4. Clean up
  rm -rf "${pkgdir}/etc/xdg/quickshell/mi-shell/scripts"
  rm -f "${pkgdir}/etc/xdg/quickshell/mi-shell/PKGBUILD"
}
