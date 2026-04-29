import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

Scope {
  id: root
  property var theme
  property var niriWorkspaces: []
  property var niriWindows: []

  // --- PINNED APPS CONFIGURATION ---
  property var pinnedApps: [
    { id: "floorp", icon: "browser", exec: "floorp" },
    { id: "org.kde.dolphin", icon: "system-file-manager", exec: "dolphin" },
    { id: "org.kde.kate", icon: "kate", exec: "kate" }
  ]

  function resolveIcon(appId) {
    if (!appId) return "application-x-executable";
    let id = appId.toLowerCase();
    const iconMap = { "kitty": "terminal", "floorp": "browser", "org.kde.kate": "kate", "nautilus": "system-file-manager", "aerc": "email", "khal": "calendar" };
    if (iconMap[id]) return iconMap[id];
    if (id.includes(".")) { let parts = id.split("."); return parts[parts.length - 1]; }
    return id;
  }

  Process {
    id: niriDataProc
    command: ["sh", "-c", "niri msg -j workspaces && echo '---SEP---' && niri msg -j windows"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          let parts = text.split('---SEP---');
          if (parts.length >= 2) {
            let ws = JSON.parse(parts[0].trim());
            ws.sort((a, b) => a.id - b.id);
            root.niriWorkspaces = ws;

            let wins = JSON.parse(parts[1].trim());
            root.niriWindows = wins
            .filter(win => win.title !== "dropdown")
            .sort((a, b) => a.pid - b.pid);
          }
        } catch(e) { console.log("Niri JSON Parse Error"); }
      }
    }
  }
  Timer { interval: 1000; running: true; repeat: true; onTriggered: niriDataProc.running = true }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; right: true }
      implicitWidth: 48
      color: root.theme.bgBase

      Item {
        anchors.fill: parent
        anchors.margins: 6

        // 1. TOP SECTION
        Item {
          id: topArea
          width: parent.width; height: 40; anchors.top: parent.top
          Rectangle {
            width: 34; height: 34; radius: 8; color: root.theme.bgSurface; anchors.centerIn: parent
            Text { text: "󰀻"; anchors.centerIn: parent; color: root.theme.accentPrimary; font.pixelSize: 18 }
            MouseArea {
              anchors.fill: parent
              onClicked: {
                let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                p.command = ["quickshell", "-c", "simon", "ipc", "call", "launcher", "toggle"];
                p.running = true;
              }
            }
          }
        }

        // 2. BOTTOM SECTION (Stats & Controls)
        Column {
          id: bottomArea
          anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width; spacing: 6

          Column {
            spacing: 6; anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
              model: root.niriWorkspaces
              Rectangle {
                required property var modelData
                width: 10; height: modelData.is_focused ? 22 : 10; radius: 5
                color: modelData.is_focused ? root.theme.accentPrimary : root.theme.bgSurface
              }
            }
          }

          Rectangle {
            width: 34; height: 42; radius: 8; color: root.theme.bgSurface
            Column {
              anchors.centerIn: parent; spacing: 2
              Text { text: "CPU"; color: root.theme.accentPrimary; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
              Text {
                id: cpuText
                text: SystemInfo.cpuUsage
                color: {
                  // Force a clean number conversion
                  let t = parseFloat(text);

                  if (t > 75) return "#fb4934"; // Red
                  if (t > 50) return "#fabd2f"; // Orange

                  return "#55aa00"; // Green (for anything 50 and below)
                }
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                id: tempText
                text: SystemInfo.temperature.replace("°C", "°")
                color: {
                  // Force a clean number conversion
                  let t = parseFloat(text);

                  if (t > 75) return "#fb4934"; // Red
                  if (t > 50) return "#fabd2f"; // Orange

                  return "#55aa00"; // Green (for anything 50 and below)
                }
                font.pixelSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }

          Column {
            spacing: 1; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
              width: 32; height: 32; radius: 16; color: root.theme.bgSurface
              Text { anchors.centerIn: parent; text: "󰃠"; color: root.theme.accentOrange; font.pixelSize: 34 }
              MouseArea {
                anchors.fill: parent
                onWheel: (wheel) => {
                  let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                  p.command = wheel.angleDelta.y > 0 ? ["brightnessctl", "set", "5%+"] : ["brightnessctl", "set", "5%-"];
                  p.running = true;
                }
              }
            }
            Rectangle {
              width: 32; height: 32; radius: 16; color: root.theme.bgSurface
              Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSink?.audio?.muted ? "󰖁" : "󰕾"; color: root.theme.accentPrimary; font.pixelSize: 34 }
              MouseArea {
                anchors.fill: parent
                onClicked: if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                onWheel: (wheel) => {
                  let s = Pipewire.defaultAudioSink?.audio;
                  if (s) s.volume = Math.max(0, Math.min(1.5, s.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                }
              }
            }
          }

          // --- SYSTEM TRAY ---
          Column {
            spacing: 1; anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
              model: SystemTray.items
              IconImage {
                required property var modelData; source: modelData.icon; implicitSize: 20

                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // Guard against undefined properties
                    let tooltip = (modelData.tooltip || "").toLowerCase();
                    let iconName = (modelData.icon || "").toLowerCase();

                    if (tooltip.includes("network") || iconName.includes("network") || iconName.includes("nm-")) {
                      let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                      // Setting a specific title makes it easy to target with Niri rules
                      p.command = ["sh", "-c", "kitty --title 'NetworkManagerUI' nmtui & disown"];
                      p.running = true;
                    }else {
                      modelData.activate();
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            id: btButton
            width: 34; height: 34; radius: 8; color: root.theme.bgSurface
            property bool isPowered: false
            Process {
              id: btWatcher
              command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
              running: true
              stdout: StdioCollector { onStreamFinished: btButton.isPowered = (text.trim() === "on") }
            }
            Text { anchors.centerIn: parent; text: !btButton.isPowered ? "󰂲" : "󰂯"; color: btButton.isPowered ? root.theme.accentPrimary : root.theme.textPrimary; font.pixelSize: 18 }
            MouseArea { anchors.fill: parent; onClicked: (mouse) => { /* bt logic */ } }
          }

          Rectangle {
            width: 36; height: 44; radius: 8; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: Time.timeString.substring(0, 5); color: root.theme.textPrimary; font.pixelSize: 14; font.bold: true }
          }
        }

        // 3. MIDDLE AREA (Window Icons & Pinned Apps)
        Item {
          anchors.top: topArea.bottom
          anchors.bottom: bottomArea.top
          anchors.topMargin: 250
          anchors.bottomMargin: 10
          width: parent.width

          Flickable {
            anchors.fill: parent
            contentHeight: windowColumn.height; clip: true

            Column {
              id: windowColumn
              width: parent.width; spacing: 12

              // --- PINNED SECTION ---
              Repeater {
                model: root.pinnedApps
                Rectangle {
                  required property var modelData
                  width: 48; height: 48; radius: 8; anchors.horizontalCenter: parent.horizontalCenter
                  property var runningWin: root.niriWindows.find(w => w.app_id === modelData.id)
                  color: runningWin?.is_focused ? root.theme.bgSurface : "transparent"
                  border.width: runningWin?.is_focused ? 1 : 0
                  border.color: root.theme.accentPrimary
                  opacity: runningWin ? 1.0 : 0.4

                  IconImage {
                    anchors.fill: parent; anchors.margins: 6
                    source: "image://icon/" + modelData.icon
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                      if (runningWin) p.command = ["niri", "msg", "action", "focus-window", "--id", runningWin.id.toString()];
                      else p.command = [modelData.exec];
                      p.running = true;
                    }
                  }
                }
              }

              // SEPARATOR
              Rectangle {
                width: 20; height: 1; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
                visible: root.niriWindows.filter(w => !root.pinnedApps.some(p => p.id === w.app_id)).length > 0
              }

              // --- DYNAMIC WINDOWS (PID Sorted) ---
              Repeater {
                model: root.niriWindows
                delegate: Rectangle {
                  required property var modelData
                  visible: !root.pinnedApps.some(p => p.id === modelData.app_id)
                  height: visible ? 34 : 0
                  width: 34; radius: 8; anchors.horizontalCenter: parent.horizontalCenter
                  color: modelData.is_focused ? root.theme.bgSurface : "transparent"
                  border.width: modelData.is_focused ? 1 : 0; border.color: root.theme.accentPrimary

                  IconImage {
                    anchors.fill: parent; anchors.margins: 6
                    source: "image://icon/" + root.resolveIcon(modelData.app_id)
                  }
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                      p.command = ["niri", "msg", "action", "focus-window", "--id", modelData.id.toString()];
                      p.running = true;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
