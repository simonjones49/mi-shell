import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Column {
  id: trayRoot

  // --- PASS-THROUGH PROPERTIES ---
  property var theme

  spacing: 6
  anchors.horizontalCenter: parent.horizontalCenter

  Repeater {
    model: SystemTray.items

    delegate: Item {
      width: 24
      height: 24
      anchors.horizontalCenter: parent.horizontalCenter

      IconImage {
        id: trayIcon
        anchors.centerIn: parent
        source: modelData.icon !== "" ? modelData.icon : "network-wireless"
        implicitWidth: 20
        implicitHeight: 20
      }

      Rectangle {
        visible: modelData.status === 2 || modelData.icon.toLowerCase().includes("attention") || modelData.icon.toLowerCase().includes("unread")
        width: 7
        height: 7
        radius: 3.5
        color: "#fb4934"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 0
        anchors.rightMargin: 0
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
          if (modelData.id.toLowerCase().includes("network") || modelData.id.toLowerCase().includes("nm-applet")) {
            if (mouse.button === Qt.RightButton) {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', trayRoot);
              p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "vpn", "toggle"];
              p.running = true;
            }
            else {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', trayRoot);
              p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "wifi", "toggle"];
              p.running = true;
            }
          } else {
            if (mouse.button === Qt.RightButton) {
              modelData.secondaryActivate();
            } else {
              modelData.activate();
            }
          }
        }
      }
    }
  }
}
