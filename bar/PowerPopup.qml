import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: powerRoot

  // --- PASS-THROUGH PROPERTIES ---
  property var theme
  property var mainBarTarget

  visible: false
  focusable: true
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  anchors { top: true; bottom: true; left: true; right: true }

  MouseArea {
    anchors.fill: parent
    onClicked: powerRoot.visible = false
    onVisibleChanged: { if (visible) powerBox.forceActiveFocus(); }
    Rectangle { anchors.fill: parent; color: powerRoot.theme.bgOverlay }
  }

  Rectangle {
    id: powerBox
    focus: true
    anchors.centerIn: parent
    width: 420; height: 120; radius: 12
    color: powerRoot.theme.bgBase; border.width: 2; border.color: powerRoot.theme.bgSurface
    Row {
      anchors.centerIn: parent; spacing: 25
      Repeater {
        model: [
          { t: "Logout", i: "󰍃", c: "#00aaff", cmd: ["niri", "msg", "action", "quit","--skip-confirmation"] },
          { t: "Reboot", i: "󰑓", c: "#00aa7f", cmd: ["systemctl", "reboot"] },
          { t: "Shut Down", i: "⏻", c: "#fb4934", cmd: ["systemctl", "poweroff"] }
        ]
        Rectangle {
          width: 110; height: 90; radius: 10
          color: pwrMouse.containsMouse ? powerRoot.theme.bgSurface : "transparent"
          Column {
            anchors.centerIn: parent; spacing: 8
            Text { text: modelData.i; color: modelData.c; font.pixelSize: 32; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: modelData.t; color: powerRoot.theme.textPrimary; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
          }
          MouseArea {
            id: pwrMouse
            anchors.fill: parent; hoverEnabled: true
            onClicked: {
              powerRoot.visible = false
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', powerRoot);
              p.command = modelData.cmd;
              p.running = true;
            }
          }
        }
      }
    }
    Keys.onEscapePressed: powerRoot.visible = false
  }
}
