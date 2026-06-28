import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

PopupWindow {
  id: popup
  property var theme
  property var currentDate
  property string agendaDetails
  property var mainBarTarget // Passed from Bar.qml

  // FIX: Correctly anchor using the passed target reference
  anchor.window: mainBarTarget
  anchor.rect.x: -300
  anchor.rect.y: mainBarTarget ? (mainBarTarget.height - 525) : 0
  implicitWidth: 280
  implicitHeight: 520
  visible: false
  color: "transparent"

  readonly property int firstDayOffset: {
    if (!popup.currentDate) return 0;
    let jsDay = new Date(popup.currentDate.getFullYear(), popup.currentDate.getMonth(), 1).getDay();
    return jsDay === 0 ? 6 : jsDay - 1;
  }
  readonly property int daysInMonth: popup.currentDate ? new Date(popup.currentDate.getFullYear(), popup.currentDate.getMonth() + 1, 0).getDate() : 30

  Connections {
    target: popup
    function onVisibleChanged() {
      if (popup.visible && typeof root !== "undefined") {
        root.currentDate = new Date();
        agendaProc.running = false;
        agendaProc.running = true;
      }
    }
  }

  Rectangle {
    anchors.fill: parent; color: popup.theme.bgBase; border.width: 1; border.color: popup.theme.bgSurface; radius: 10

    Item {
      anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 10
      width: 24; height: 24; z: 10
      Text { text: "󰅖"; color: popup.theme.textMuted; anchors.centerIn: parent; font.pixelSize: 20 }
      MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible = false
      }
    }

    Column {
      anchors.fill: parent; anchors.margins: 15; spacing: 15

      Text {
        text: popup.currentDate ? Qt.formatDateTime(popup.currentDate, "MMMM yyyy").toUpperCase() : "";
        color: popup.theme.textPrimary; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
      }

      Item {
        width: parent.width
        height: 240
        anchors.horizontalCenter: parent.horizontalCenter

        GridLayout {
          id: calendarGrid
          anchors.fill: parent
          columns: 7
          rowSpacing: 10
          columnSpacing: 8

          Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Text { text: modelData; color: popup.theme.accentPrimary; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
          }

          Repeater {
            model: popup.firstDayOffset
            Item { implicitWidth: 30; implicitHeight: 30 }
          }

          Repeater {
            model: popup.daysInMonth
            delegate: Rectangle {
              implicitWidth: 30; implicitHeight: 30
              radius: 4
              readonly property int dayNum: index + 1
              readonly property bool isToday: popup.currentDate ? (dayNum === popup.currentDate.getDate() &&
              new Date().getMonth() === popup.currentDate.getMonth() &&
              new Date().getFullYear() === popup.currentDate.getFullYear()) : false

              color: isToday ? popup.theme.accentPrimary : "transparent"
              Text {
                anchors.centerIn: parent
                text: dayNum
                color: isToday ? popup.theme.bgBase : popup.theme.textPrimary
                font.bold: isToday
              }
            }
          }

          Repeater {
            model: 42 - (popup.firstDayOffset + popup.daysInMonth)
            Item { implicitWidth: 30; implicitHeight: 30 }
          }
        }
      }

      Rectangle { width: parent.width; height: 1; color: popup.theme.bgSurface }

      Item {
        width: parent.width
        height: 24

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Upcoming events"
          color: popup.theme.accentPrimary
          font.pixelSize: 16
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: "󰃭"
          color: popup.theme.accentPrimary
          font.pixelSize: 22

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', popup);
              p.command = ["sh", "-c", "kitty --config $HOME/.config/kitty/calendar.conf --class calendar -e ikhal"];
              p.running = true;
              popup.visible = false;
            }
          }
        }
      }

      ScrollView {
        width: parent.width; height: 140; clip: true
        Text {
          width: parent.width
          text: popup.agendaDetails
          color: popup.theme.textPrimary
          font.pixelSize: 13
          font.family: "Monospace"
          wrapMode: Text.Wrap
        }
      }
    }
  }
}
