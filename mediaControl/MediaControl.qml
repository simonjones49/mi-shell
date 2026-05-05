import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}

  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing);
    return playing || players[0];
  }

  property bool popupVisible: false
  // Added a local property to force UI updates
  property real currentPos: activePlayer ? activePlayer.position : 0

  IpcHandler {
    target: "media"
    function toggle(): void { root.popupVisible = !root.popupVisible; }
  }

  Timer {
    id: posTimer
    interval: 500
    running: root.popupVisible && root.activePlayer !== null
    repeat: true
    onTriggered: {
      if (root.activePlayer) {
        root.currentPos = root.activePlayer.position;
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: mediaWindow
      required property var modelData
      screen: modelData
      visible: root.popupVisible

      focusable: true
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "quickshell-media"
      exclusionMode: ExclusionMode.Ignore
      anchors.top: true
      anchors.right: true
      WlrLayershell.margins { top: 3; right: 50 }

      implicitWidth: 340
      implicitHeight: contentCol.implicitHeight + 40

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        radius: 12

        ColumnLayout {
          id: contentCol
          anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
          anchors.margins: 20; spacing: 18

          // 1. ALBUM ART
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 300; Layout.preferredHeight: 300
            radius: 8; color: root.theme.bgSurface; clip: true

            Text {
              anchors.centerIn: parent
              text: "󰎆"; color: root.theme.textMuted; font.pixelSize: 80; font.family: "Hack Nerd Font"
              visible: albumArtImage.status !== Image.Ready
            }

            Image {
              id: albumArtImage
              anchors.fill: parent
              source: root.activePlayer?.trackArtUrl ?? ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              opacity: status === Image.Ready ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 200 } }
            }
          }

          // 2. INFO
          ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            Text {
              text: root.activePlayer?.trackTitle ?? "No Media Detected"
              color: root.theme.textPrimary; font.pixelSize: 18; font.bold: true
              elide: Text.ElideRight; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            }
            Text {
              text: root.activePlayer?.trackArtist ?? "Unknown Artist"
              color: root.theme.accentPrimary; font.pixelSize: 14; elide: Text.ElideRight
              Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
            }
          }

          // 3. PROGRESS (Revised Logic)
          ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            visible: root.activePlayer !== null && root.activePlayer.length > 0
            Rectangle {
              id: progressBg
              Layout.fillWidth: true; height: 6; radius: 3; color: root.theme.bgSurface
              Rectangle {
                // Using currentPos for reactive updates
                width: (root.activePlayer && root.activePlayer.length > 0)
                ? parent.width * (root.currentPos / root.activePlayer.length)
                : 0
                height: parent.height; radius: 3; color: root.theme.accentPrimary
              }
              MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                  if (root.activePlayer && root.activePlayer.length > 0) {
                    let newPos = (mouse.x / width) * root.activePlayer.length;
                    root.activePlayer.position = newPos;
                    root.currentPos = newPos; // Instant visual feedback
                  }
                }
              }
            }
            RowLayout {
              Layout.fillWidth: true
              Text { text: formatTime(root.currentPos); color: root.theme.textMuted; font.pixelSize: 10 }
              Item { Layout.fillWidth: true }
              Text { text: formatTime(root.activePlayer?.length ?? 0); color: root.theme.textMuted; font.pixelSize: 10 }
            }
          }

          // 4. VOLUME
          RowLayout {
            Layout.fillWidth: true; spacing: 10
            visible: root.activePlayer !== null

            Text {
              text: root.activePlayer?.volume > 0 ? "󰕾" : "󰝟"
              font.family: "Hack Nerd Font"; font.pixelSize: 16; color: root.theme.textMuted
            }

            Rectangle {
              id: volBar
              Layout.fillWidth: true; height: 6; radius: 3; color: root.theme.bgSurface
              Rectangle {
                width: volBar.width * (root.activePlayer?.volume ?? 0)
                height: parent.height; radius: 3; color: root.theme.accentPrimary
              }
              MouseArea {
                anchors.fill: parent
                preventStealing: true
                onPressed: (mouse) => { if (root.activePlayer) root.activePlayer.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                onPositionChanged: (mouse) => { if (root.activePlayer) root.activePlayer.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                onWheel: (wheel) => {
                  if (root.activePlayer) {
                    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    root.activePlayer.volume = Math.max(0, Math.min(1, root.activePlayer.volume + delta));
                  }
                }
              }
            }
          }

          // 5. CONTROLS
          RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 40
            visible: root.activePlayer !== null

            Text {
              text: "󰒮"; font.pixelSize: 28; font.family: "Hack Nerd Font"; color: root.theme.textPrimary
              MouseArea {
                anchors.fill: parent
                onClicked: { if (root.activePlayer) root.activePlayer.previous(); }
              }
            }

            Rectangle {
              width: 60; height: 60; radius: 30; color: root.theme.accentPrimary
              Text {
                anchors.centerIn: parent
                text: (root.activePlayer?.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                color: root.theme.bgBase; font.pixelSize: 32; font.family: "Hack Nerd Font"
              }
              MouseArea {
                anchors.fill: parent
                onClicked: { if (root.activePlayer) root.activePlayer.togglePlaying(); }
              }
            }

            Text {
              text: "󰒭"; font.pixelSize: 28; font.family: "Hack Nerd Font"; color: root.theme.textPrimary
              MouseArea {
                anchors.fill: parent
                onClicked: { if (root.activePlayer) root.activePlayer.next(); }
              }
            }
          }
        }
      }
    }
  }

  function formatTime(seconds) {
    if (!seconds || seconds < 0) return "0:00";
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }
}
