import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
  property string currentTemp: "--"

  property var pinnedApps: [
    { id: "floorp", icon: "browser", exec:
      "floorp" },
    { id: "org.kde.dolphin", icon: "system-file-manager", exec: "dolphin" },
    { id: "org.kde.kate", icon: "kate", exec: "kate" }
  ]


  function resolveIcon(appId) {
    if (!appId) return "application-x-executable";
    let id = appId.toLowerCase();
    const iconMap = { "kitty": "terminal", "floorp": "browser", "org.kde.kate": "kate", "nautilus": "system-file-manager", "aerc": "email", "khal": "calendar", "endcord": "discord" };
    if (iconMap[id]) return iconMap[id];
    if (id.includes(".")) { let parts = id.split("."); return parts[parts.length - 1]; }
    return id;
  }

  // --- DATA FETCHING ---
  Process {
    id: niriProc
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
            root.niriWindows = wins.filter(win => win.title !== "dropdown").sort((a, b) => a.pid - b.pid);
          }
        } catch(e) {}
      }
    }
  }
  Timer { interval: 1000; running: true; repeat: true; onTriggered: niriProc.running = true }

  Process {
    id: tempProc
    command: ["cat", "/sys/class/thermal/thermal_zone0/temp"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        let cleanText = text.trim().split('\n')[0];
        let t = parseInt(cleanText);
        if (!isNaN(t)) root.currentTemp = Math.round(t / 1000).toString() + "°";
      }
    }
  }
  Timer { interval: 2000; running: true; repeat: true; onTriggered: tempProc.running = true }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: mainBar
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; right: true }
      implicitWidth: 48
      color: root.theme.bgBase

      // --- CALENDAR POPUP ---
      PopupWindow {
        id: calendarPopup
        anchor.window: mainBar
        anchor.rect.x: -210
        anchor.rect.y: mainBar.height - 300
        implicitWidth: 200; implicitHeight: 250; // Increased height slightly to fit the button
        visible: false

        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface; radius: 0
          Column {
            anchors.fill: parent; anchors.margins: 10; spacing: 10

            Text {
              text: Qt.formatDateTime(new Date(), "MMMM yyyy");
              color: root.theme.accentPrimary; font.bold: true;
              anchors.horizontalCenter: parent.horizontalCenter
            }

            Grid {
              columns: 7; spacing: 5; anchors.horizontalCenter: parent.horizontalCenter
              Repeater {
                model: 31;
                Rectangle {
                  width: 22; height: 22; radius: 4;
                  color: (index + 1 == new Date().getDate()) ? root.theme.accentPrimary : "transparent";
                  Text { text: index + 1; anchors.centerIn: parent; color: (index + 1 == new Date().getDate()) ? root.theme.bgBase : root.theme.textPrimary; font.pixelSize: 12 }
                }
              }
            }

            // --- iKhal Launcher Button ---
            Rectangle {
              width: parent.width; height: 32; color: root.theme.bgSurface; radius: 6
              Text {
                text: "Open iKhal";
                color: root.theme.accentPrimary;
                font.bold: true;
                font.pixelSize: 11;
                anchors.centerIn: parent
              }
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
                onClicked: {
                  let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                  p.command = ["kitty", "-e", "ikhal"];
                  p.running = true;
                  calendarPopup.visible = false; // Fixed: closes the calendar, not the power menu
                }
              }
            }
          }
        }
      }

      // --- POWER POPUP (Replaces the standard Menu for better movement) ---
      PopupWindow {
        id: powerPopup
        anchor.window: mainBar
        anchor.rect.x: -130
        anchor.rect.y: mainBar.height - 120
        implicitWidth: 120; implicitHeight: 110; visible: false
        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface; radius: 0
          Column {
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            // Manual Buttons for reliability
            Rectangle {
              width: parent.width; height: 30; color: "transparent"; radius: 4
              Text { text: "Logout"; color: root.theme.textPrimary; anchors.centerIn: parent }
              MouseArea { anchors.fill: parent; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); p.command = ["niri", "msg", "action", "quit"]; p.running = true; powerPopup.visible = false; } }
            }
            Rectangle {
              width: parent.width; height: 30; color: "transparent"; radius: 4
              Text { text: "Reboot"; color: root.theme.textPrimary; anchors.centerIn: parent }
              MouseArea { anchors.fill: parent; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); p.command = ["systemctl", "reboot"]; p.running = true; powerPopup.visible = false; } }
            }
            Rectangle {
              width: parent.width; height: 30; color: "transparent"; radius: 4
              Text { text: "Shut Down"; color: "#fb4934"; anchors.centerIn: parent }
              MouseArea { anchors.fill: parent; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); p.command = ["systemctl", "poweroff"]; p.running = true; powerPopup.visible = false; } }
            }
          }
        }
      }

      Item {
        anchors.fill: parent
        anchors.margins: 6

        // TOP SECTION
        Item { id: topArea; width: parent.width; height: 40; anchors.top: parent.top
          Rectangle { width: 34; height: 34; radius: 8; color: root.theme.bgSurface; anchors.centerIn: parent
            Text { text: "󰀻"; anchors.centerIn: parent; color: root.theme.accentPrimary; font.pixelSize: 36 }
            MouseArea { anchors.fill: parent; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "launcher", "toggle"]; p.running = true; } }
          }
        }

        // MIDDLE SECTION (Pinned Apps)
        // Simplified anchoring to ensure they don't disappear
        Column {
          id: middleArea
          y: 350 // Direct Y positioning
          width: parent.width
          spacing: 8

          Repeater {
            model: root.pinnedApps
            Rectangle {
              required property var modelData; width: 42; height: 42; radius: 8; anchors.horizontalCenter: parent.horizontalCenter
              property var runningWin: root.niriWindows.find(w => w.app_id === modelData.id)
              color: runningWin?.is_focused ? root.theme.bgSurface : "transparent"
              border.width: runningWin?.is_focused ? 1 : 0; border.color: root.theme.accentPrimary
              opacity: runningWin ? 1.0 : 0.4
              IconImage { anchors.fill: parent; anchors.margins: 4; source: "image://icon/" + modelData.icon }
              MouseArea { anchors.fill: parent; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); if (runningWin) p.command = ["niri", "msg", "action", "focus-window", "--id", runningWin.id.toString()]; else p.command = [modelData.exec]; p.running = true; } }
            }
          }


          Rectangle { width: 20; height: 1; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter; visible: root.niriWindows.filter(w => !root.pinnedApps.some(p => p.id === w.app_id)).length > 0 }

          Repeater {
            model: root.niriWindows
            delegate: Rectangle {
              required property var modelData; visible: !root.pinnedApps.some(p => p.id === modelData.app_id)
              height: visible ? 34 : 0; width: 34; radius: 8; anchors.horizontalCenter: parent.horizontalCenter
              color: modelData.is_focused ? root.theme.bgSurface : "transparent"; border.width: modelData.is_focused ? 1 : 0; border.color: root.theme.accentPrimary
              IconImage { anchors.fill: parent; anchors.margins: 2; source: "image://icon/" + root.resolveIcon(modelData.app_id) }
              MouseArea { anchors.fill: parent; onClicked: { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); p.command = ["niri", "msg", "action", "focus-window", "--id", modelData.id.toString()]; p.running = true; } }
            }
          }
        }

        // BOTTOM SECTION
        Column {
          id: bottomArea; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; spacing: 8

          // Workspaces
          Column { spacing: 6; anchors.horizontalCenter: parent.horizontalCenter; Repeater { model: root.niriWorkspaces; Rectangle { required property var modelData; width: 10; height: modelData.is_focused ? 22 : 10; radius: 5; color: modelData.is_focused ? root.theme.accentPrimary : root.theme.bgSurface } } }

          // Stats
          Rectangle { width: 38; height: 45; radius: 8; color: root.theme.bgSurface
            Column { anchors.centerIn: parent; spacing: 1
              Text { text: "CPU"; color: root.theme.accentPrimary; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: SystemInfo.cpuUsage; font.pixelSize: 10; color: parseFloat(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: root.currentTemp; font.pixelSize: 10; color: parseInt(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
            }
          }

          // Controls & Tray
          Column { spacing: 2; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { width: 32; height: 32; radius: 16; color: root.theme.bgSurface; Text { anchors.centerIn: parent; text: "󰃠"; color: root.theme.accentOrange; font.pixelSize: 22 }
            MouseArea { anchors.fill: parent; onWheel: (wheel) => { let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root); p.command = wheel.angleDelta.y > 0 ? ["brightnessctl", "set", "5%+"] : ["brightnessctl", "set", "5%-"]; p.running = true; } }
            }
            Rectangle { width: 32; height: 32; radius: 16; color: root.theme.bgSurface; Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSink?.audio?.muted ? "󰖁" : "󰕾"; color: root.theme.accentPrimary; font.pixelSize: 22 }
            MouseArea { anchors.fill: parent; onClicked: if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted; onWheel: (wheel) => { let s = Pipewire.defaultAudioSink?.audio; if (s) s.volume = Math.max(0, Math.min(1.5, s.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))); } }
            }
          }
          Column {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
              model: SystemTray.items
              IconImage {
                required property var modelData
                source: modelData.icon
                implicitSize: 20

                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    // Check if the item is nm-applet (it usually identifies as 'nm-applet' or 'network')
                    if (modelData.id.toLowerCase().includes("network") || modelData.id.toLowerCase().includes("nm-applet")) {
                      let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                      p.command = ["kitty", "-e", "nmtui"];
                      p.running = true;
                    } else {
                      // Standard activation for other items (Bluetooth, Discord, etc.)
                      modelData.activate();
                    }
                  }
                }
              }
            }
          }

          // Clock
          Rectangle { width: 36; height: 44; radius: 8; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: Time.timeString.substring(0, 5); color: root.theme.textPrimary; font.pixelSize: 14; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: calendarPopup.visible = !calendarPopup.visible }
          }

          // Power Button (Triggering the new PopupWindow)
          Rectangle { width: 34; height: 34; radius: 17; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: "⏻"; color: "#fb4934"; font.pixelSize: 18 }
            MouseArea { anchors.fill: parent; onClicked: powerPopup.visible = !powerPopup.visible }
          }
        }
      }
    }
  }
}
