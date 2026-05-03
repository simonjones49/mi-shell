import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Mpris

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

  property var player: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  Timer {
    id: progressTimer
    interval: 500
    running: controlCentre.visible && controlCentre.player && controlCentre.player.isPlaying
    repeat: true
    onTriggered: {
      if (controlCentre.player && controlCentre.player.length > 0) {
        const progress = controlCentre.player.position / controlCentre.player.length;
        progressFill.width = progressBackground.width * progress;
      }
    }
  }
  PanelWindow {
    id: powerPopup
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    MouseArea {
      anchors.fill: parent
      onClicked: powerPopup.visible = false
      onVisibleChanged: { if (visible) powerBox.forceActiveFocus(); }
      Rectangle { anchors.fill: parent; color: "#AA000000" } // Dimmed background
    }

    Rectangle {
      id: powerBox
      focus: true
      anchors.centerIn: parent
      width: 420; height: 120; radius: 12
      color: controlCentre.theme.bgBase; border.width: 2; border.color: controlCentre.theme.bgSurface

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
            color: pwrMouse.containsMouse ? controlCentre.theme.bgSurface : "transparent"
            Column {
              anchors.centerIn: parent; spacing: 8
              Text { text: modelData.i; color: modelData.c; font.family: "Hack Nerd Font"; font.pixelSize: 32; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: modelData.t; color: "#FFFFFF"; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea {
              id: pwrMouse; anchors.fill: parent; hoverEnabled: true
              onClicked: {
                powerPopup.visible = false
                let p = Qt.createQmlObject('import Quickshell.Io; Process {}', controlCentre);
                p.command = modelData.cmd;
                p.running = true;
              }
            }
          }
        }
      }
      Keys.onEscapePressed: powerPopup.visible = false
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
    height: 230 // Adjusted height for two rows
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
        Layout.alignment: Qt.AlignHCenter
        spacing: 15 // Slightly wider spacing looks better when centered

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
              p.command = ["kitty", "--class", "networkmanager", "-e", "nmtui"];
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
              p.command = ["gtk-launch" , "VPN\ Switch.desktop"];
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
              p.command = ["kitty", "--class", "bluetooth", "-e", "bluetui"];              p.running = true;
              controlCentre.visible = false;
            }
          }
        }


      }

      // Row 2: Appearance
      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 15 // Slightly wider spacing looks better when centered

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
          }        }

      }
      // Row 3: Session
      RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 15 // Slightly wider spacing looks better when centered

        Rectangle {
          id: openPowerBtn
          Layout.preferredWidth: 60; Layout.preferredHeight: 45; radius: 8
          color: pwrTriggerMouse.containsMouse ? controlCentre.theme.bgSelected : controlCentre.theme.bgSurface

          Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.family: "Hack Nerd Font"; font.pixelSize: 20; color: "#FFFFFF"
          }

          MouseArea {
            id: pwrTriggerMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: {
              controlCentre.visible = false; // Close the menu
              // Trigger the external popup - we'll use its ID directly
              powerPopup.visible = true;
            }
          }
        }
      }

      // --- MEDIA PLAYER ---
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        Layout.topMargin: 10
        radius: 10
        color: controlCentre.theme.bgSurface
        clip: true

        RowLayout {
          anchors.fill: parent
          anchors.margins: 15
          spacing: 15

          Rectangle {
            Layout.preferredWidth: 120; Layout.preferredHeight: 120; radius: 8
            color: controlCentre.theme.bgBase
            Image {
              anchors.fill: parent
              source: controlCentre.player ? controlCentre.player.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              visible: status === Image.Ready
            }
            Text {
              anchors.centerIn: parent; text: "󰎆"; font.family: "Hack Nerd Font"
              font.pixelSize: 40; color: controlCentre.theme.textMuted
              visible: !controlCentre.player || controlCentre.player.trackArtUrl === ""
            }
          }

          ColumnLayout {
            Layout.fillWidth: true; spacing: 2

            Text {
              text: controlCentre.player ? controlCentre.player.trackTitle : "No Media"
              color: "white"; font.bold: true; font.pixelSize: 14
              elide: Text.ElideRight; Layout.fillWidth: true
            }

            Text {
              text: controlCentre.player ? controlCentre.player.trackArtist : "Idle"
              color: "#aaaaaa"; font.pixelSize: 12
              elide: Text.ElideRight; Layout.fillWidth: true
            }

            Rectangle {
              id: progressBackground
              Layout.fillWidth: true; Layout.preferredHeight: 4; Layout.topMargin: 10
              color: controlCentre.theme.bgBase; radius: 2

              Rectangle {
                id: progressFill
                width: 0
                height: parent.height; color: controlCentre.theme.accentPrimary; radius: 2
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.Linear } }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => {
                  if (controlCentre.player && controlCentre.player.length > 0) {
                    const ratio = mouse.x / width;
                    controlCentre.player.position = ratio * controlCentre.player.length;
                    progressFill.width = width * ratio;
                  }
                }
              }
            }

            RowLayout {
              Layout.alignment: Qt.AlignHCenter
              Layout.topMargin: 10; spacing: 15

              Text {
                text: "󰒮"; font.family: "Hack Nerd Font"; font.pixelSize: 18
                color: (controlCentre.player && controlCentre.player.canGoPrevious) ? "white" : "#555555"
                MouseArea { anchors.fill: parent; onClicked: if (controlCentre.player && controlCentre.player.canGoPrevious) controlCentre.player.previous() }
              }

              Rectangle {
                width: 36; height: 36; radius: 18; color: controlCentre.theme.accentPrimary
                Text {
                  anchors.centerIn: parent; text: controlCentre.player && controlCentre.player.isPlaying ? "󰏤" : "󰐊"
                  color: controlCentre.theme.bgBase; font.family: "Hack Nerd Font"
                }
                MouseArea { anchors.fill: parent; onClicked: if (controlCentre.player) controlCentre.player.togglePlaying() }
              }

              Text {
                text: "󰒭"; font.family: "Hack Nerd Font"; font.pixelSize: 18
                color: (controlCentre.player && controlCentre.player.canGoNext) ? "white" : "#555555"
                MouseArea { anchors.fill: parent; onClicked: if (controlCentre.player && controlCentre.player.canGoNext) controlCentre.player.next() }
              }
            }
          }
        }
      }
      Item { Layout.fillHeight: true }
    }
  }
}
