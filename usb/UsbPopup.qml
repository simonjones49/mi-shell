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
    height: driveColumn.implicitHeight + 32

    color: usbPopup.theme.bgBase
    radius: 12
    border.color: usbPopup.theme.bgBorder
    border.width: 1

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: driveColumn
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
        color: usbPopup.theme.accentPrimary
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

          MouseArea {
            id: driveMouse
            anchors.fill: parent
            hoverEnabled: !modelData.encrypted || !!modelData.mountpoint
            onClicked: {
              let isLuks = modelData.name.startsWith("luks-");
              let devName = modelData.name.startsWith("/dev/") ? modelData.name :
              (isLuks ? "/dev/mapper/" + modelData.name : "/dev/" + modelData.name);

              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', usbPopup);

              if (modelData.mountpoint) {
                p.command = [
                  "sh", "-c",
                  `DEV="${devName}"; ` +
                  // Extracts the raw parent name (e.g., sdb1) directly from the UDisks2 object path
                  `BACKING=$(udisksctl info -b "$DEV" | grep "CryptoBackingDevice:" | cut -d"'" -f2 | sed 's|.*/||'); ` +
                  `udisksctl unmount -b "$DEV" && ` +
                  `if [ -n "$BACKING" ]; then ` +
                  `  sleep 1; ` +
                  `  udisksctl lock -b "/dev/$BACKING"; ` +
                  `fi`
                ];
                p.running = true;
              } else if (modelData.encrypted) {
                // Encrypted & Locked -> Do nothing. User unlocks manually.
                return;
              } else {
                // Normal unmounted drive -> Standard Mount
                p.command = ["udisksctl", "mount", "-b", devName];
                p.running = true;
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
              text: modelData.mountpoint ? "󱐩" : (modelData.encrypted ? "󰌾" : "󱊞")
              font.family: "Hack Nerd Font"
              font.pixelSize: 14
              color: modelData.mountpoint ? usbPopup.theme.accentPrimary : (modelData.encrypted ? "#fabd2f" : usbPopup.theme.textPrimary)
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2
              Text {
                text: (modelData.label || modelData.name.split('/').pop()) + " (" + modelData.size + ")"
                color: usbPopup.theme.textPrimary
                font.bold: true
                elide: Text.ElideRight
              }
              Text {
                text: modelData.mountpoint
                ? "Click to Unmount & Lock"
                : (modelData.encrypted ? "Encrypted • Please Unlock" : "Click to Mount")
                color: (modelData.encrypted && !modelData.mountpoint) ? "#fabd2f" : usbPopup.theme.accentPrimary
                font.pixelSize: 10
                opacity: 0.8
              }
            }

            // --- Open Folder Button ---
            Rectangle {
              visible: !!modelData.mountpoint
              Layout.preferredWidth: 32
              Layout.preferredHeight: 32
              radius: 16
              color: openMouse.containsMouse ? usbPopup.theme.bgSurface : "transparent"
              border.width: openMouse.containsMouse ? 1 : 0
              border.color: usbPopup.theme.accentPrimary

              Text {
                anchors.centerIn: parent
                text: "󰝰"
                font.family: "Hack Nerd Font"
                font.pixelSize: 16
                color: usbPopup.theme.accentPrimary
              }

              MouseArea {
                id: openMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: (mouse) => {
                  mouse.accepted = true;
                  let openProc = Qt.createQmlObject('import Quickshell.Io; Process {}', usbPopup);
                  openProc.command = ["xdg-open", modelData.mountpoint];
                  openProc.running = true;
                  usbPopup.visible = false;
                }
              }
            }

            // --- Power Off / Secure Lock Button ---
            Rectangle {
              id: powerBtn
              visible: true
              Layout.preferredWidth: 32
              Layout.preferredHeight: 32
              radius: 16
              color: powerMouse.containsMouse ? "#fb4934" : "transparent"

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
                onClicked: (mouse) => {
                  mouse.accepted = true;
                  let isLuks = modelData.name.startsWith("luks-");
                  let devName = modelData.name.startsWith("/dev/") ? modelData.name :
                  (isLuks ? "/dev/mapper/" + modelData.name : "/dev/" + modelData.name);

                  let powerTeardown = Qt.createQmlObject('import Quickshell.Io; Process {}', usbPopup);
                  powerTeardown.command = [
                    "sh", "-c",
                    `DEV="${devName}"; ` +
                    `BACKING=$(udisksctl info -b "$DEV" | grep "CryptoBackingDevice:" | cut -d"'" -f2 | sed 's|.*/||'); ` +
                    `if udisksctl info -b "$DEV" | grep -q "MountPoints:[[:space:]]*[^[:space:]]"; then ` +
                    `  udisksctl unmount -b "$DEV"; ` +
                    `  sleep 1; ` +
                    `fi; ` +
                    `if [ -n "$BACKING" ]; then ` +
                    `  udisksctl lock -b "/dev/$BACKING"; ` +
                    `  RAW_DISK=$(echo "$BACKING" | sed 's/[0-9]\\+$//'); ` +
                    `else ` +
                    `  RAW_DISK=$(echo "$DEV" | sed 's|.*/||' | sed 's/[0-9]\\+$//'); ` +
                    `fi; ` +
                    `if [ -n "$RAW_DISK" ]; then ` +
                    `  udisksctl power-off -b "/dev/$RAW_DISK"; ` +
                    `fi`
                  ];

                  powerTeardown.running = true;
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
