import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: usbPopup
  property var theme: DefaultTheme {}

  visible: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  anchors { top: true; bottom: true; left: true; right: true }

  IpcHandler {
    target: "usbpopupcomp"
    function toggle(): void {
      usbPopup.visible = !usbPopup.visible;
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: usbPopup.visible = false
  }

  Rectangle {
    id: usbBox
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 10
    anchors.rightMargin: 10

    width: 300
    // FIX: Remove the complex Math.min from here and let the Column decide
    height: driveColumn.implicitHeight + 32

    color: usbPopup.theme.bgBase
    radius: 12
    border.color: usbPopup.theme.bgBorder
    border.width: 1

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: driveColumn
      // FIX: Use anchors.top and anchors.left/right instead of fill: parent
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 16
      spacing: 12

      Text {
        text: "󱊞  USB Drives"
        font.family: "Hack Nerd Font"
        font.pixelSize: 14
        font.bold: true
        color: usbPopup.theme.textPrimary
      }

      Text {
        visible: usbMonitor.driveList.length === 0
        text: "No drives detected"
        color: usbPopup.theme.textPrimary
        opacity: 0.5
        font.italic: true
      }

      Repeater {
        model: usbMonitor.driveList
        delegate: Rectangle {
          id: driveRow
          Layout.fillWidth: true
          Layout.preferredHeight: 50
          color: driveMouse.containsMouse ? usbPopup.theme.bgSurface : "transparent"
          radius: 6

          // 1. This MouseArea now sits ON TOP of the whole row
          MouseArea {
            id: driveMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              let action = modelData.mountpoint ? "unmount" : "mount";
              let devName = modelData.name.startsWith("/dev/") ? modelData.name : "/dev/" + modelData.name;
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', usbPopup);
              p.command = ["udisksctl", action, "-b", devName];
              p.running = true;
              usbPopup.visible = false;
            }
          }

          // 2. The Layout contains the visuals
          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            // Icon
            Text {
              text: modelData.mountpoint ? "󱐩" : "󱊞"
              font.family: "Hack Nerd Font"
              font.pixelSize: 20
              color: modelData.mountpoint ? usbPopup.theme.accentPrimary : usbPopup.theme.textPrimary
            }

            // Drive Name and Subtext
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2
              Text {
                text: (modelData.label || modelData.name) + " (" + modelData.size + ")"
                color: usbPopup.theme.textPrimary
                font.bold: true
                elide: Text.ElideRight
              }
              Text {
                text: modelData.mountpoint ? "Click to Unmount" : "Click to Mount"
                color: usbPopup.theme.accentPrimary
                font.pixelSize: 10
                opacity: 0.8
              }
            }

            // Power Off Button (Safely Remove)
            Rectangle {
              id: powerBtn
              Layout.preferredWidth: 32
              Layout.preferredHeight: 32
              radius: 16
              color: powerMouse.containsMouse ? "#fb4934" : "transparent"

              // CHANGE THIS: Show only when mounted
              visible: modelData.mountpoint

              Text {
                anchors.centerIn: parent
                text: "⏻"
                font.family: "Hack Nerd Font"
                font.pixelSize: 16
                color: powerMouse.containsMouse ? "white" : usbPopup.theme.accentPrimary
              }

              MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  let devName = modelData.name.startsWith("/dev/") ? modelData.name : "/dev/" + modelData.name;

                  // 1. Create a process to Unmount first
                  let unmountProc = Qt.createQmlObject('import Quickshell.Io; Process {}', usbPopup);
                  unmountProc.command = ["udisksctl", "unmount", "-b", devName];

                  // 2. When unmount finishes (success or fail), try to Power Off
                  unmountProc.runningChanged.connect(function() {
                    if (!unmountProc.running) {
                      let powerProc = Qt.createQmlObject('import Quickshell.Io; Process {}', usbPopup);
                      powerProc.command = ["udisksctl", "power-off", "-b", devName];
                      powerProc.running = true;
                    }
                  });

                  unmountProc.running = true;
                  usbPopup.visible = false;
                }
              }
            }
          }
        }
      }
      Item { Layout.fillHeight: true }
    }
  }
}
