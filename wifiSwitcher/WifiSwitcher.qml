import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Scope {
  id: root
  property var theme: Theme
  property string statusMessage: "Select a network to connect:"
  property string connectedSsid: ""
  property bool isScanning: false

  // ==========================================
  // BACKEND DATA MODELS & METHODS
  // ==========================================
  ListModel {
    id: wifiModel
  }

  function startScan() {
    wifiModel.clear();
    root.connectedSsid = "";
    root.statusMessage = "Scanning for networks...";
    scanProcess.running = true;
  }

  // ==========================================
  // IPC CHANNELS
  // ==========================================
  IpcHandler {
    target: "wifi"

    function toggle(): void {
      wifiPanel.visible = !wifiPanel.visible;
      if (wifiPanel.visible) {
        startScan();
        wifiBox.forceActiveFocus();
      }
    }

    function forceScan(): void {
      startScan();
    }
  }

  // ==========================================
  // BACKGROUND PROCESS WORKERS
  // ==========================================
  Timer {
    id: closeTimer
    interval: 1500
    repeat: false
    onTriggered: {
      wifiPanel.visible = false;
      startScan();
    }
  }

  Process {
    id: scanProcess
    command: ["nmcli", "-t", "-f", "SSID,SECURITY,ACTIVE", "dev", "wifi"]

    stdout: SplitParser {
      splitMarker: "\n"
      onRead: (line) => {
        if (line.trim() === "") return;
        let parts = line.split(":");
        if (parts.length < 3) return;

        let ssid = parts[0];
        let security = parts[1];
        let active = parts[2] === "yes";

        if (active) {
          root.connectedSsid = ssid;
        } else if (ssid !== "") {
          let exists = false;
          for (let i = 0; i < wifiModel.count; i++) {
            if (wifiModel.get(i).ssid === ssid) {
              exists = true;
              break;
            }
          }
          if (!exists) {
            wifiModel.append({ "ssid": ssid, "security": security });
          }
        }
      }
    }

    onExited: {
      root.isScanning = false;
      if (root.connectedSsid !== "") {
        root.statusMessage = "Connected to: " + root.connectedSsid;
      } else {
        root.statusMessage = "Select a network to connect:";
      }
    }
  }

  Process {
    id: connectProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        root.statusMessage = "✅ Successfully Connected!";
        closeTimer.start();
      } else {
        root.statusMessage = "❌ Connection failed.";
        startScan();
      }
    }
  }

  Process {
    id: disconnectProcess
    onExited: (exitCode, exitStatus) => {
      console.log(" quickshell-wifi: Disconnect process completed with exit code:", exitCode);
      if (exitCode === 0) {
        root.connectedSsid = "";
        root.statusMessage = "🔌 Disconnected successfully.";
        startScan();
      } else {
        root.statusMessage = "❌ Disconnect failed (Exit Code " + exitCode + ").";
      }
    }
  }

  Process {
    id: vpnCaller
    command: ["quickshell", "-c", "mi-shell", "ipc", "call", "vpn", "toggle"]
  }
  // ==========================================
  // FULL SCREEN OVERLAY PANEL WINDOW
  // ==========================================
  PanelWindow {
    id: wifiPanel // 👈 FIX: Renamed from root to eliminate the unique ID collision error
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-wifi"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Dark overlay backdrop intercepting click-to-close events
    MouseArea {
      anchors.fill: parent
      onClicked: {
        wifiPanel.visible = false;
      }

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgOverlay
      }
    }

    // Centered Wi-Fi Manager Box
    Rectangle {
      id: wifiBox
      anchors.centerIn: parent
      width: 550
      height: 480
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      focus: true

      // 👈 FIX: Directing escape sequence properly to the PanelWindow instance
      Keys.onEscapePressed: wifiPanel.visible = false

      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // Header Title
        Text {
          text: "📡 Network Manager"
          color: root.theme.accentPrimary
          font.pixelSize: 14
          font.family: "Hack Nerd Font"
          font.bold: true
          Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Dynamic Status Tracker Text
        Text {
          Layout.fillWidth: true
          text: root.statusMessage
          color: root.theme.textMuted
          font.pixelSize: 12
          font.family: "Hack Nerd Font"
          wrapMode: Text.Wrap
          Behavior on color { ColorAnimation { duration: 150 } }
        }

        // Interactive Active Network Row / Disconnect Handle
        Rectangle {
          Layout.fillWidth: true
          height: 44
          radius: 8
          visible: root.connectedSsid !== ""
          color: root.theme.bgSelected
          border.color: root.theme.accentPrimary
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Text {
              text: "Active:  " + root.connectedSsid
              color: root.theme.textPrimary
              font.family: "Hack Nerd Font"
              font.pixelSize: 13
              font.bold: true
              Layout.fillWidth: true
            }

            // Cleanly bounded button component
            Rectangle {
              id: disconnectBtn
              width: disconnectLabel.width + 16
              height: 26
              radius: 6
              color: disconnectMouseArea.containsMouse ? root.theme.bgHover : "transparent"
              border.color: disconnectMouseArea.containsMouse ? (root.theme.accentRed || "#ff5555") : "transparent"
              border.width: 1

              Text {
                id: disconnectLabel
                anchors.centerIn: parent
                text: "Disconnect 🔌"
                color: root.theme.accentRed || "#ff5555"
                font.family: "Hack Nerd Font"
                font.pixelSize: 12
                font.bold: true
              }

              MouseArea {
                id: disconnectMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  console.log(" quickshell-wifi: Disconnect clicked for SSID:", root.connectedSsid);
                  root.statusMessage = "Disconnecting...";

                  disconnectProcess.command = [
                    "sh", "-c",
                    "nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev | grep :wifi | cut -d: -f1)"
                  ];
                  disconnectProcess.running = true;
                }
              }
            }
          }
        }

        // Scanned Access Points List
        ListView {
          id: networkListView
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: wifiModel
          clip: true
          spacing: 4
          boundsBehavior: Flickable.StopAtBounds

          // No results fallback indicator
          Text {
            anchors.centerIn: parent
            text: "No networks found nearby."
            color: root.theme.textMuted
            font.pixelSize: 13
            font.family: "Hack Nerd Font"
            visible: networkListView.count === 0 && !scanProcess.running
          }

          delegate: Rectangle {
            id: itemDelegate
            required property var modelData
            required property int index

            width: networkListView.width
            height: 40
            radius: 8
            color: rowHoverArea.containsMouse ? root.theme.bgHover : root.theme.bgSurface

            Behavior on color { ColorAnimation { duration: 100 } }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 10

              Text {
                text: itemDelegate.modelData.ssid
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: "Hack Nerd Font"
                Layout.fillWidth: true
              }

              // Padlock Security Glyph
              Text {
                text: "🔒"
                color: root.theme.textMuted
                font.pixelSize: 12
                visible: itemDelegate.modelData.security !== ""
              }
            }

            MouseArea {
              id: rowHoverArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.statusMessage = "Connecting to " + itemDelegate.modelData.ssid + "...";
                connectProcess.command = ["nmcli", "device", "wifi", "connect", itemDelegate.modelData.ssid];
                connectProcess.running = true;
                wifiPanel.visible = false;
              }
            }
          }
        }

        // Control Action Footer
        RowLayout {
          Layout.fillWidth: true

          Rectangle {
            width: refreshLabel.width + 16
            height: 26
            radius: 6
            color: root.theme.bgSurface
            border.color: footerMouseArea.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1

            Text {
              id: refreshLabel
              anchors.centerIn: parent
              text: "🔄 Rescan Airspace"
              color: root.theme.textSecondary
              font.pixelSize: 11
              font.family: "Hack Nerd Font"
            }

            MouseArea {
              id: footerMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.startScan()
            }
          }

          Item { Layout.fillWidth: true }

          // Esc Hint Button
          Row {
            spacing: 4
            Rectangle {
              width: 32; height: 18; radius: 4; color: root.theme.bgSurface
              Text { anchors.centerIn: parent; text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font" }
            }
            Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
          }
          Rectangle {
            width: vpnBtnLabel.width + 16
            height: 26
            radius: 6
            color: root.theme.bgSurface
            border.color: vpnMouseArea.containsMouse ? root.theme.accentPrimary : root.theme.bgBorder
            border.width: 1

            Text {
              id: vpnBtnLabel
              anchors.centerIn: parent
              text: "🔒 Open VPN"
              color: root.theme.textSecondary
              font.pixelSize: 11
              font.family: "Hack Nerd Font"
            }

            MouseArea {
              id: vpnMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                vpnCaller.running = true; // This will trigger the command
                wifiPanel.visible = false;
              }
            }
          }
        }
      }
    }
  }
}
