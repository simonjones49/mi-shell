import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

PopupWindow {
  id: cpuPopup

  // --- PASS-THROUGH PROPERTIES ---
  property var mainBarTarget
  property var theme
  property string sysDetails
  property var sysDetailProcTarget

  anchor.window: mainBarTarget
  anchor.rect.x: -300
  anchor.rect.y: mainBarTarget.height - 710
  implicitWidth: 280
  implicitHeight: 180
  visible: false
  color: "transparent"

  Connections {
    target: cpuPopup
    function onVisibleChanged() {
      if (cpuPopup.visible && sysDetailProcTarget) {
        sysDetailProcTarget.running = false;
        sysDetailProcTarget.running = true;
      }
    }
  }

  Rectangle {
    anchors.fill: parent; color: theme.bgBase; border.width: 1; border.color: theme.bgSurface; radius: 10
    Item {
      anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
      width: 20; height: 20
      Text { text: "󰅖"; color: theme.textMuted; anchors.centerIn: parent; font.pixelSize: 18 }
      MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: cpuPopup.visible = false
      }
    }
    Column {
      anchors.fill: parent; anchors.margins: 12; spacing: 8
      Text { text: "System Info"; color: theme.accentPrimary; font.bold: true; font.pixelSize: 14 }
      Text { text: cpuPopup.sysDetails; color: theme.textPrimary; font.pixelSize: 14; font.family: "Monospace" }
    }
  }
}
