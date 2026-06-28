import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
  id: root
  property var theme

  WlrLayershell.layer: WlrLayer.Overlay
  focusable: true
  color: "transparent"
  visible: false

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // State properties
  property string statusMessage: "Select a VPN to connect:"
  property string activeVpn: ""
  property var vpnList: []
  property bool isScanning: false
  property bool showCredsForm: false
  property string pendingVpn: "" // 👈 Tracks the target VPN during execution

  // Keyring credentials state
  property string inputUsername: ""
  property string inputPassword: ""

  // ==========================================
  // PROCESS HANDLERS (System Automation)
  // ==========================================

  // Fetch available and active VPNs
  Process {
    id: scanProcess
    command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "con"]
    stdout: StdioCollector { id: scanCollector }

    onExited: (exitCode, exitStatus) => {
      root.isScanning = false;
      if (exitCode === 0) {
        let safeStdout = scanCollector.text || "";
        let lines = safeStdout.trim().split("\n");
        let listBuffer = [];
        let activeBuffer = "";

        if (safeStdout.trim() !== "") {
          for (let i = 0; i < lines.length; i++) {
            let parts = lines[i].split(":");
            if (parts.length >= 3) {
              let name = parts[0];
              let type = parts[1].toLowerCase().trim();
              let state = parts[2].toLowerCase().trim();

              if (type === "vpn" || type === "wireguard") {
                if (state === "activated") {
                  activeBuffer = name;
                } else {
                  listBuffer.push(name);
                }
              }
            }
          }
        }
        root.vpnList = listBuffer;
        root.activeVpn = activeBuffer;
        if (activeBuffer !== "") {
          root.statusMessage = "🔒 Connected to: " + activeBuffer;
        } else if (!root.showCredsForm) {
          root.statusMessage = "Select a VPN connection:";
        }
      } else {
        root.statusMessage = "❌ Failed to fetch connection states.";
      }
    }
  }

  // 👈 FIX: Consolidated all connection logic cleanly inside the declarative block
  Process {
    id: connectProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 42) {
        root.statusMessage = "🔑 Credentials not found in keyring.";
        root.showCredsForm = true;
      } else if (exitCode === 0) {
        root.statusMessage = "✅ Connected to " + root.pendingVpn;
        root.visible = false;
      } else {
        root.statusMessage = "❌ Connection failed.";
        startScan();
      }
      root.pendingVpn = "";
    }
  }

  // Disconnect Active VPN
  Process {
    id: disconnectProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        root.activeVpn = "";
        root.statusMessage = "🔌 VPN disconnected.";
        startScan();
      } else {
        root.statusMessage = "❌ Disconnect failed.";
      }
    }
  }

  // Save Credentials to System Keyring via Python
  Process {
    id: saveCredsProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        root.statusMessage = "🔑 Credentials saved securely!";
        root.showCredsForm = false;
        startScan();
      } else {
        root.statusMessage = "❌ Keyring write failed.";
      }
    }
  }

  // Helper functions
  function startScan() {
    if (!root.isScanning) {
      root.isScanning = true;
      scanProcess.running = true;
    }
  }

  function executeConnect(vpnName) {
    root.pendingVpn = vpnName; // Save state for the process completion message
    root.statusMessage = "Connecting to " + vpnName + "...";

    let shellCmd =
    "username=$(python -c 'import keyring; print(keyring.get_password(\"PrivadoVPN\", \"main_username\") or \"\")'); " +
    "password=$(python -c 'import keyring; print(keyring.get_password(\"PrivadoVPN\", \"main_password\") or \"\")'); " +
    "if [ -z \"$username\" ] || [ -z \"$password\" ]; then exit 42; fi; " +
    "if nmcli -t -f NAME,STATE con | grep -q ':activated$'; then " +
    "  nmcli con down id \"$(nmcli -t -f NAME,STATE con | grep ':activated$' | cut -d: -f1)\"; " +
    "fi; " +
    "printf \"$username\\n$password\\n\" | nmcli --ask con up id \"" + vpnName + "\"";

    connectProcess.command = ["sh", "-c", shellCmd];
    connectProcess.running = true;
  }

  // ==========================================
  // IPC CHANNELS
  // ==========================================
  IpcHandler {
    target: "vpn"

    function toggle(): void {
      root.visible = !root.visible;
      if (root.visible) {
        startScan();
        vpnBox.forceActiveFocus();
      }
    }
    function forceScan(): void { startScan(); }
  }

  // ==========================================
  // USER INTERFACE LAYOUT
  // ==========================================
  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Rectangle {
    id: vpnBox
    anchors.centerIn: parent
    width: 550
    height: 480
    radius: 16
    color: root.theme.bgBase
    border.color: root.theme.bgBorder
    border.width: 1

    focus: true
    Keys.onEscapePressed: root.visible = false

    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 15

      // Header Title Block
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "VPN Manager"
          color: root.theme.textPrimary
          font.family: "Hack Nerd Font"
          font.pixelSize: 18
          font.bold: true
        }
        Item { Layout.fillWidth: true }
        Text {
          text: root.isScanning ? "⏳" : "🔄"
          color: root.theme.textSecondary
          font.pixelSize: 14
          MouseArea {
            anchors.fill: parent
            onClicked: startScan()
          }
        }
      }

      // Interactive Status Bar
      Rectangle {
        Layout.fillWidth: true
        height: 38
        radius: 8
        color: root.theme.bgSelected
        Text {
          anchors.centerIn: parent
          text: root.statusMessage
          color: root.theme.textPrimary
          font.family: "Hack Nerd Font"
          font.pixelSize: 12
        }
      }

      // Main Core Content Area (Conditional Screens)
      StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.showCredsForm ? 1 : 0

        // VIEW 0: Active Connection Management & VPN List
        ColumnLayout {
          spacing: 12

          // Active Connection Block
          Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 8
            visible: root.activeVpn !== ""
            color: root.theme.bgSelected
            border.color: root.theme.accentPrimary
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14

              Text {
                text: "Active:  " + root.activeVpn
                color: root.theme.textPrimary
                font.family: "Hack Nerd Font"
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
              }

              Rectangle {
                width: disconnectLabel.width + 16
                height: 26
                radius: 6
                color: disconnectMA.containsMouse ? root.theme.bgHover : "transparent"
                border.color: disconnectMA.containsMouse ? root.theme.accentRed : "transparent"
                border.width: 1

                Text {
                  id: disconnectLabel
                  anchors.centerIn: parent
                  text: "Turn Off 🔌"
                  color: root.theme.accentRed
                  font.family: "Hack Nerd Font"
                  font.pixelSize: 12
                  font.bold: true
                }

                MouseArea {
                  id: disconnectMA
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.statusMessage = "Deactivating VPN...";
                    disconnectProcess.command = ["nmcli", "con", "down", "id", root.activeVpn];
                    disconnectProcess.running = true;
                  }
                }
              }
            }
          }

          // Scrollable Unconnected VPN List
          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: vpnListColumn.height
            clip: true

            Text {
              anchors.centerIn: parent
              text: "No VPN or WireGuard connections configured."
              color: root.theme.textSecondary
              font.family: "Hack Nerd Font"
              font.pixelSize: 13
              visible: root.vpnList.length === 0 && root.activeVpn === "" && !root.isScanning
            }

            Column {
              id: vpnListColumn
              width: parent.width
              spacing: 6

              Repeater {
                model: root.vpnList
                delegate: Rectangle {
                  width: parent.width
                  height: 40
                  radius: 6
                  color: itemMA.containsMouse ? root.theme.bgHover : root.theme.bgSelected

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    Text {
                      text: "🌐  " + modelData
                      color: root.theme.textPrimary
                      font.family: "Hack Nerd Font"
                      font.pixelSize: 13
                      Layout.fillWidth: true
                    }

                    Text {
                      text: "Connect"
                      color: root.theme.accentPrimary
                      font.family: "Hack Nerd Font"
                      font.pixelSize: 12
                      visible: itemMA.containsMouse
                    }
                  }

                  MouseArea {
                    id: itemMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: executeConnect(modelData)
                  }
                }
              }
            }
          }

          // Button to manually configure/reset stored credentials
          Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 6
            color: "transparent"
            border.color: root.theme.bgBorder

            Text {
              anchors.centerIn: parent
              text: "✏️ Update Saved Keyring Credentials"
              color: root.theme.textSecondary
              font.family: "Hack Nerd Font"
              font.pixelSize: 11
            }
            MouseArea {
              anchors.fill: parent
              onClicked: {
                root.inputUsername = "";
                root.inputPassword = "";
                root.showCredsForm = true;
              }
            }
          }
        }

        // VIEW 1: Keyring Setup Form
        ColumnLayout {
          spacing: 14

          Text {
            text: "PrivadoVPN Keyring Configuration"
            color: root.theme.textPrimary
            font.bold: true
            font.pixelSize: 13
          }

          TextField {
            Layout.fillWidth: true
            placeholderText: "Enter Username"
            text: root.inputUsername
            onTextChanged: root.inputUsername = text
            selectByMouse: true
          }

          TextField {
            Layout.fillWidth: true
            placeholderText: "Enter Password"
            echoMode: TextInput.Password
            text: root.inputPassword
            onTextChanged: root.inputPassword = text
            selectByMouse: true
          }

          RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignRight

            Button {
              text: "Cancel"
              onClicked: {
                root.showCredsForm = false;
                startScan();
              }
            }

            Button {
              text: "Save to Keyring"
              enabled: root.inputUsername !== "" && root.inputPassword !== ""
              onClicked: {
                root.statusMessage = "Writing to secure keyring...";
                let saveCmd =
                "python -c 'import keyring; " +
                "keyring.set_password(\"PrivadoVPN\", \"main_username\", \"" + root.inputUsername + "\"); " +
                "keyring.set_password(\"PrivadoVPN\", \"main_password\", \"" + root.inputPassword + "\")'";
                saveCredsProcess.command = ["sh", "-c", saveCmd];
                saveCredsProcess.running = true;
              }
            }
          }
          Item { Layout.fillHeight: true }
        }
      }
    }
  }

  Component.onCompleted: startScan()
}
