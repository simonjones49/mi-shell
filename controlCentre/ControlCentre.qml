import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
  id: controlCentre
  property var theme: Theme

  visible: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  anchors { top: true; bottom: true; left: true; right: true }

  IpcHandler {
    target: "controlcentre"
    function toggle(): void {
      controlCentre.visible = !controlCentre.visible;
    }
  }

  // Dismiss layer
  MouseArea {
    anchors.fill: parent
    onClicked: controlCentre.visible = false
  }

  Rectangle {
    id: controlBox
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 60
    anchors.rightMargin: 10

    width: 300
    height: 200 // Adjusted height for two rows
    color: controlCentre.theme.bgBase
    radius: 12
    border.color: controlCentre.theme.bgBorder
    border.width: 1

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 15

      Text {
        text: "󰄄  Control Centre"
        font.family: "Hack Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: controlCentre.theme.accentPrimary
      }

      // Row 1: Connections
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Wi-Fi
        Rectangle {
          id: wifiBtn
          Layout.preferredWidth: 60; Layout.preferredHeight: 45; radius: 8
          color: wifiMouse.containsMouse ? controlCentre.theme.bgSelected : controlCentre.theme.bgSurface
          Text { anchors.centerIn: parent; text: "󰖩"; font.family: "Hack Nerd Font"; font.pixelSize: 20; color: "#FFFFFF" }
          MouseArea {
            id: wifiMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', controlCentre);
              p.command = ["kitty", "--class", "nmtui-float", "-e", "nmtui"];
              p.running = true;
              controlCentre.visible = false;
            }
          }
        }

        // Bluetooth
        Rectangle {
          id: btBtn
          Layout.preferredWidth: 60; Layout.preferredHeight: 45; radius: 8
          color: btMouse.containsMouse ? controlCentre.theme.bgSelected : controlCentre.theme.bgSurface
          Text { anchors.centerIn: parent; text: "󰂯"; font.family: "Hack Nerd Font"; font.pixelSize: 20; color: "#FFFFFF" }
          MouseArea {
            id: btMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', controlCentre);
              p.command = ["blueman-manager"];
              p.running = true;
              controlCentre.visible = false;
            }
          }
        }

        // VPN
        Rectangle {
          id: vpnBtn
          Layout.preferredWidth: 60; Layout.preferredHeight: 45; radius: 8
          color: vpnMouse.containsMouse ? controlCentre.theme.bgSelected : controlCentre.theme.bgSurface
          Text { anchors.centerIn: parent; text: "󰦝"; font.family: "Hack Nerd Font"; font.pixelSize: 20; color: "#FFFFFF" }
          MouseArea {
            id: vpnMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', controlCentre);
              p.command = ["sh", "-c", "python3 $HOME/bin/combined_vpn_wg_switcher.py"];
              p.running = true;
              controlCentre.visible = false;
            }
          }
        }
      }

      // Row 2: Appearance
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Wallpaper
        Rectangle {
          id: wallBtn
          Layout.preferredWidth: 60; Layout.preferredHeight: 45; radius: 8
          color: wallMouse.containsMouse ? controlCentre.theme.bgSelected : controlCentre.theme.bgSurface
          Text { anchors.centerIn: parent; text: "󰸉"; font.family: "Hack Nerd Font"; font.pixelSize: 20; color: "#FFFFFF" }
          MouseArea {
            id: wallMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', controlCentre);
              p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "wallpaper", "toggle"];
              p.running = true;
              controlCentre.visible = false;
            }
          }
        }

        // Theme
        Rectangle {
          id: themeBtn
          Layout.preferredWidth: 60; Layout.preferredHeight: 45; radius: 8
          color: themeMouse.containsMouse ? controlCentre.theme.bgSelected : controlCentre.theme.bgSurface
          Text { anchors.centerIn: parent; text: "󰏘"; font.family: "Hack Nerd Font"; font.pixelSize: 20; color: "#FFFFFF" }
          MouseArea {
            id: themeMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', controlCentre);
              p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "theme", "toggle"];
              p.running = true;
              controlCentre.visible = false;
            }
          }
        }
      }
      Item { Layout.fillHeight: true }
    }
  }
}
