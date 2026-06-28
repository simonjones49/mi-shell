//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"
import "notifications"
import "themeSwitcher"
import "wifiSwitcher"
import "vpnSwitcher"
import "wallpaper"
import "osd"
import "controlCentre"
import "mediaControl"
import "usb"
import "timer"
import "niriEngine"
import "system"
Scope {

  ThemeSwitcher { id: ts }

  WifiSwitcher {
    id: wifi
    theme: ts.theme
  }
  VpnSwitcher {
    id: vpn
    theme: ts.theme
  }
  Bar {
    theme: ts.theme
  }
  AppLauncher { theme: ts.theme }
  NotificationPopup { theme: ts.theme }
  WallpaperManager { theme: ts.theme }
  OSD { theme: ts.theme }
  ControlCentre {
    id: controlCentre
    theme: ts.theme
  }
    MediaControl { theme: ts.theme }
    UsbLogic { id: usbMonitor }
    UsbPopup { id: usbPopupComp; theme: ts.theme }
    MasterTimer { id: masterTimer }
    NiriEngine { id: niriEngine }
    SystemEngine { id: systemEngine }
}
