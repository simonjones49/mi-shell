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

  // --- PROPERTIES ---
  property var theme
  property var niriWorkspaces: []
  property var niriWindows: []
  property string currentTemp: "--"
  property string sysDetails: "Loading stats..."
  property string agendaDetails: "No upcoming events."
  property string calOutput: ""

  property var pinnedApps: [
    { id: "floorp", icon: "browser", exec: "floorp" },
    { id: "org.kde.dolphin", icon: "system-file-manager", exec: "dolphin" },
    { id: "org.kde.kate", icon: "kate", exec: "kate" }
  ]

  // --- HELPER FUNCTIONS ---
  function resolveIcon(appId) {
    if (!appId) return "application-x-executable";
    let id = appId.toLowerCase();
    const iconMap = {
      "kitty": "terminal",
      "floorp": "browser",
      "org.kde.kate": "kate",
      "nautilus": "system-file-manager",
      "aerc": "email",
      "khal": "calendar",
      "endcord": "discord",
      "watch-videos": "video-x-generic"
    };
    if (iconMap[id]) return iconMap[id];
    if (id.includes(".")) {
      let parts = id.split(".");
      return parts[parts.length - 1];
    }
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
  Process {
    id: calProc
    // The <pre> tag forces the UI to respect the newlines and spacing exactly as 'cal' sends them
    command: ["sh", "-c", "cal -m | sed -E 's/\\b" + new Date().getDate() + "\\b/<font color=\"#fb4934\">" + new Date().getDate() + "<\\/font>/'"]
    running: root.theme !== undefined

    stdout: StdioCollector {
      onStreamFinished: {
        let lines = text.split('\n');
        if (lines.length > 1) {
          lines.shift();
          // Wrapping the whole thing in <pre> tags
          root.calOutput = "<pre>" + lines.join('\n') + "</pre>";
        }
      }
    }
  }
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

  Process {
    id: sysDetailProc
    command: ["sh", "-c", "grep PRETTY_NAME /etc/os-release | cut -d'\"' -f2 && uname -r && uptime -p | sed 's/up //; s/ days*/d/; s/ hours*/h/; s/ minutes*/m/; s/,//g' && free -h | awk '/^Mem:/ {print $3 \" / \" $2}' && df -h / | awk 'NR==2 {print $3 \" / \" $2}' && df -h /home | awk 'NR==2 {print $3 \" / \" $2}'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        let lines = text.trim().split('\n');
        if (lines.length >= 5) {
          root.sysDetails = "Distro: " + lines[0] + "\n" +
          "Kernel: " + lines[1] + "\n" +
          "Uptime: " + lines[2] + "\n" +
          "RAM    : " + lines[3] + "\n" +
          "Disk /: " + lines[4]  + "\n" +
          "Home  : " + lines[5];
        }
      }
    }
  }

  Process {
    id: agendaProc
    command: ["sh", "-c", "khal list --notstarted now 7d --format '{start-time} {title}' --day-format '{name}, {date}'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        let cleanText = text.trim();
        root.agendaDetails = cleanText.length > 0 ? cleanText : "No events scheduled.";
      }
    }
  }

  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: if (!niriProc.running) niriProc.running = true
  }

  // --- WINDOW RENDER ---
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: mainBar
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; right: true }
      implicitWidth: 48
      color: root.theme.bgBase

      // --- POPUPS ---

      PopupWindow {
        id: cpuPopup
        anchor.window: mainBar
        anchor.rect.x: -300
        anchor.rect.y: mainBar.height - 685
        implicitWidth: 280
        implicitHeight: 180
        visible: false
        Connections {
          target: cpuPopup
          function onVisibleChanged() { if (cpuPopup.visible) { sysDetailProc.running = false; sysDetailProc.running = true; } }
        }
        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface
          Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 8
            Text { text: "System Info"; color: root.theme.accentPrimary; font.bold: true; font.pixelSize: 14 }
            Text { text: root.sysDetails; color: root.theme.textPrimary; font.pixelSize: 14; font.family: "Monospace" }
          }
        }
      }

      PopupWindow {
        id: calendarPopup
        anchor.window: mainBar
        anchor.rect.x: -300
        anchor.rect.y: mainBar.height - 500
        implicitWidth: 280
        implicitHeight: 500
        visible: false
        Connections {
          target: calendarPopup
          function onVisibleChanged() {
            if (calendarPopup.visible) {
              // Force the processes to restart by toggling running to false then true
              calProc.running = false;
              calProc.running = true;

              agendaProc.running = false;
              agendaProc.running = true;
            }
          }
        }
        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface
          Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 12
            Text {
              text: Qt.formatDateTime(new Date(), "MMMM yyyy");
              color: root.theme.accentPrimary; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
              text: root.calOutput
              textFormat: Text.StyledText
              color: root.theme.textPrimary
              font.family: "Monospace" // CRITICAL for grid alignment
              font.pixelSize: 17
              lineHeight: 1.2
              horizontalAlignment: Text.AlignLeft // Better for calendar grids
              anchors.horizontalCenter: parent.horizontalCenter
            }
            Rectangle { width: parent.width; height: 1; color: root.theme.bgSurface }
            Text { text: "Upcoming events"; color: root.theme.accentPrimary; font.bold: true; font.pixelSize: 14 }
            ScrollView {
              width: parent.width; height: 160; clip: true
              Text { width: 250; text: root.agendaDetails; color: root.theme.textPrimary; font.pixelSize: 13; font.family: "Monospace"; wrapMode: Text.Wrap }
            }
            Rectangle {
              width: parent.width; height: 32; color: root.theme.bgSurface; radius: 6
              Text { text: "Open iKhal"; color: root.theme.accentPrimary; font.bold: true; font.pixelSize: 11; anchors.centerIn: parent }
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                  p.command = ["kitty", "-e", "ikhal"];
                  p.running = true;
                  calendarPopup.visible = false;
                }
              }
            }
          }
        }
      }

      PopupWindow {
        id: powerPopup
        anchor.window: mainBar
        anchor.rect.x: -130
        anchor.rect.y: mainBar.height - 120
        implicitWidth: 120; implicitHeight: 110; visible: false
        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface
          Column {
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            Repeater {
              model: [
                { t: "Logout", c: root.theme.textPrimary, cmd: ["niri", "msg", "action", "quit"] },
                { t: "Reboot", c: root.theme.textPrimary, cmd: ["systemctl", "reboot"] },
                { t: "Shut Down", c: "#fb4934", cmd: ["systemctl", "poweroff"] }
              ]
              Rectangle {
                width: 110; height: 30; color: "transparent"
                Text { text: modelData.t; color: modelData.c; anchors.centerIn: parent }
                MouseArea {
                  anchors.fill: parent
                  onClicked: {
                    let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                    p.command = modelData.cmd;
                    p.running = true;
                  }
                }
              }
            }
          }
        }
      }

      // --- MAIN BAR CONTENT ---
      Item {
        anchors.fill: parent
        anchors.margins: 6

        // Launcher Toggle
        Rectangle {
          width: 34; height: 34; radius: 8; color: root.theme.bgSurface; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
          Text { text: "󰀻"; anchors.centerIn: parent; color: root.theme.accentPrimary; font.pixelSize: 36 }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
              p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "launcher", "toggle"];
              p.running = true;
            }
          }
        }

        // Apps
        Column {
          y: 350; width: parent.width; spacing: 8
          Repeater {
            model: root.pinnedApps
            Rectangle {
              width: 42; height: 42; radius: 8; anchors.horizontalCenter: parent.horizontalCenter
              property var runningWin: root.niriWindows.find(w => w.app_id === modelData.id)
              color: runningWin?.is_focused ? root.theme.bgSurface : "transparent"
              border.width: runningWin?.is_focused ? 1 : 0; border.color: root.theme.accentPrimary
              opacity: runningWin ? 1.0 : 0.4
              IconImage { anchors.fill: parent; anchors.margins: 4; source: "image://icon/" + modelData.icon }
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                  if (runningWin)
                    p.command = ["niri", "msg", "action", "focus-window", "--id", runningWin.id.toString()];
                  else
                    p.command = [modelData.exec];
                  p.running = true;
                }
              }
            }
          }

          // Unpinned Windows
          Repeater {
            model: root.niriWindows
            delegate: Rectangle {
              visible: !root.pinnedApps.some(p => p.id === modelData.app_id)
              height: visible ? 34 : 0; width: 34; radius: 8; anchors.horizontalCenter: parent.horizontalCenter
              color: modelData.is_focused ? root.theme.bgSurface : "transparent"
              border.width: modelData.is_focused ? 1 : 0; border.color: root.theme.accentPrimary
              IconImage { anchors.fill: parent; anchors.margins: 2; source: "image://icon/" + root.resolveIcon(modelData.app_id) }
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

        // Status Area
        Column {
          anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; spacing: 8

          // Workspaces
          MouseArea {
            width: parent.width; height: wsColumn.height; anchors.horizontalCenter: parent.horizontalCenter
            onWheel: (wheel) => {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
              p.command = wheel.angleDelta.y < 0 ? ["niri", "msg", "action", "focus-workspace-down"] : ["niri", "msg", "action", "focus-workspace-up"];
              p.running = true;
            }
            Column {
              id: wsColumn; spacing: 6; anchors.horizontalCenter: parent.horizontalCenter
              Repeater {
                model: root.niriWorkspaces
                Rectangle { width: 10; height: modelData.is_focused ? 22 : 10; radius: 5; color: modelData.is_focused ? root.theme.accentPrimary : root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter }
              }
            }
          }

          // CPU/Temp
          Rectangle {
            width: 38; height: 45; radius: 8; color: root.theme.bgSurface
            Column {
              anchors.centerIn: parent; spacing: 1
              Text { text: "CPU"; color: root.theme.accentPrimary; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: SystemInfo.cpuUsage; font.pixelSize: 11; color: parseFloat(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: root.currentTemp; font.pixelSize: 11; color: parseInt(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea { anchors.fill: parent; onClicked: cpuPopup.visible = !cpuPopup.visible }
          }

          // Vol/Bright
          Column {
            spacing: 2; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
              width: 32; height: 32; radius: 16; color: root.theme.bgSurface
              Text { anchors.centerIn: parent; text: "󰃠"; color: root.theme.accentOrange; font.pixelSize: 22 }
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
              Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSink?.audio?.muted ? "󰖁" : "󰕾"; color: root.theme.accentPrimary; font.pixelSize: 22 }
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

          // Tray
          Column {
            spacing: 4; anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
              model: SystemTray.items
              IconImage {
                source: modelData.icon; implicitSize: 20
                MouseArea {
                  anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) modelData.secondaryActivate();
                    else modelData.activate();
                  }
                }
              }
            }
          }

          // Time
          Rectangle {
            width: 36; height: 44; radius: 8; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: Time.timeString.substring(0, 5); color: root.theme.textPrimary; font.pixelSize: 14; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: calendarPopup.visible = !calendarPopup.visible }
          }

          // Power
          Rectangle {
            width: 34; height: 34; radius: 17; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: "⏻"; color: "#fb4934"; font.pixelSize: 18 }
            MouseArea { anchors.fill: parent; onClicked: powerPopup.visible = !powerPopup.visible }
          }
        }
      }
    }
  }
}
