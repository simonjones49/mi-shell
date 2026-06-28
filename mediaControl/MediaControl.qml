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
  property real currentPos: activePlayer ? activePlayer.position : 0

  // --- VIDEO ART WORKAROUND EXTENSION ---
  property string generatedArtUrl: ""
  property string lastProcessedUrl: ""
  property bool extractionFailed: false
  property var ffmpegArgs: []
  property bool toggleCachePath: false // Alternates files to cleanly break Qt's strict local image cache

  onActivePlayerChanged: checkAndExtractArt()
  Connections {
    target: root.activePlayer ? root.activePlayer : null
    // Explicitly listen to metadata changes where xesam URL structures are packaged
    function onMetadataChanged() { root.checkAndExtractArt(); }
    function onTrackArtUrlChanged() { root.checkAndExtractArt(); }
  }

  function checkAndExtractArt() {
    if (!root.activePlayer) {
      root.generatedArtUrl = "";
      root.lastProcessedUrl = "";
      return;
    }

    // 1. If native MPRIS cover art exists (standard audio albums), use it directly
    if (root.activePlayer.trackArtUrl && root.activePlayer.trackArtUrl !== "") {
      root.extractionFailed = false;
      root.generatedArtUrl = root.activePlayer.trackArtUrl;
      return;
    }

    // FIX: Read from metadata map directly
    const currentUrl = root.activePlayer.metadata ? (root.activePlayer.metadata["xesam:url"] ?? "") : "";
    if (currentUrl === "" || currentUrl === root.lastProcessedUrl) return;
    root.lastProcessedUrl = currentUrl;

    console.log("mi-shell-media: Processing target URL -> " + currentUrl);

    // 2. Bonus: Handle direct YouTube stream targets without calling ffmpeg
    if (currentUrl.includes("youtube.com/watch") || currentUrl.includes("youtu.be/")) {
      root.extractionFailed = false;
      let videoId = "";
      if (currentUrl.includes("youtube.com/watch")) {
        let match = currentUrl.match(/[?&]v=([\w-]{11})/);
        if (match) videoId = match[1];
      } else {
        let match = currentUrl.match(/youtu\.be\/([\w-]{11})/);
        if (match) videoId = match[1];
      }

      if (videoId !== "") {
        root.generatedArtUrl = "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg";
        return;
      }
    }

    // 3. Handle local media container parsing via backend ffmpeg extraction
    if (currentUrl.startsWith("file://")) {
      root.extractionFailed = false;

      let cleanPath = decodeURIComponent(currentUrl.replace(/^file:\/\//, ""));
      let targetFile = root.toggleCachePath ? "/tmp/quickshell-thumb-b.jpg" : "/tmp/quickshell-thumb-a.jpg";

      root.ffmpegArgs = [
        "ffmpeg", "-y",
        "-ss", "00:00:10", // Skips forward 2s to minimize landing on black screen transitions
        "-i", cleanPath,
        "-an", "-vframes", "1", "-q:v", "3",
        targetFile
      ];

      executionTrigger.start();
    } else {
      root.generatedArtUrl = "";
    }
  }

  Timer {
    id: executionTrigger
    interval: 10
    repeat: false
    onTriggered: {
      if (artExtractor.running) artExtractor.running = false;
      artExtractor.running = true;
    }
  }

  Process {
    id: artExtractor
    command: root.ffmpegArgs

    onRunningChanged: {
      if (!running) {
        // Expose new image location safely using standard absolute references
        root.generatedArtUrl = "file://" + (root.toggleCachePath ? "/tmp/quickshell-thumb-b.jpg" : "/tmp/quickshell-thumb-a.jpg");
        root.toggleCachePath = !root.toggleCachePath;
      }
    }
  }
  // --- END EXTENSION ---

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
      WlrLayershell.margins { top: 10; right: 60 }

      implicitWidth: 340
      implicitHeight: contentCol.implicitHeight + 40

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1
        radius: 12

        Item {
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: 6
          width: 24
          height: 24
          z: 100

          Text {
            anchors.centerIn: parent
            text: "󰅖"
            font.family: "Hack Nerd Font"
            font.pixelSize: 20
            color: closeMouse.containsMouse ? root.theme.accentPrimary : root.theme.textMuted
          }

          MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.popupVisible = false
          }
        }

        ColumnLayout {
          id: contentCol
          anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
          anchors.margins: 20; spacing: 18

          // 1. ALBUM ART CONTAINER
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 300; Layout.preferredHeight: 300
            radius: 8; color: root.theme.bgSurface; clip: true

            Text {
              anchors.centerIn: parent
              text: root.extractionFailed ? "󰈡" : "󰎆"
              color: root.theme.textMuted; font.pixelSize: 80; font.family: "Hack Nerd Font"
              visible: albumArtImage.status !== Image.Ready
            }

            Image {
              id: albumArtImage
              anchors.fill: parent
              source: root.generatedArtUrl
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              opacity: (status === Image.Ready && !root.extractionFailed) ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: 200 } }

              onStatusChanged: {
                if (status === Image.Error) {
                  root.extractionFailed = true;
                }
              }
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

          // 3. PROGRESS
          ColumnLayout {
            Layout.fillWidth: true; spacing: 6
            visible: root.activePlayer !== null && root.activePlayer.length > 0
            Rectangle {
              id: progressBg
              Layout.fillWidth: true; height: 6; radius: 3; color: root.theme.bgSurface
              Rectangle {
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
                    root.currentPos = newPos;
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
