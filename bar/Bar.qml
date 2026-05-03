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
  property bool numLockActive: false
  property bool capsLockActive: false

  // --- TIMERS & PROCESSES ---
  Timer {
    interval: 500
    running: true
    repeat: true
    onTriggered: {
      numLockCheck.running = false;
      numLockCheck.running = true;
      capsLockCheck.running = false;
      capsLockCheck.running = true;
    }
  }

  Process {
    id: numLockCheck
    command: ["sh", "-c", "grep -q '1' /sys/class/leds/*::numlock/brightness && echo '1' || echo '0'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { root.numLockActive = (text.trim() === "1"); }
    }
  }

  Process {
    id: capsLockCheck
    command: ["sh", "-c", "grep -q '1' /sys/class/leds/*::capslock/brightness && echo '1' || echo '0'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { root.capsLockActive = (text.trim() === "1"); }
    }
  }

  property var pinnedApps: [
    { id: "floorp", icon: "browser", exec: "floorp" },
    { id: "org.kde.dolphin", icon: "system-file-manager", exec: "dolphin" },
    { id: "org.kde.kate", icon: "kate", exec: "kate" }
  ]

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
        anchor.rect.y: mainBar.height - 710
        implicitWidth: 280
        implicitHeight: 180
        visible: false
        color: "transparent"
        Connections {
          target: cpuPopup
          function onVisibleChanged() { if (cpuPopup.visible) { sysDetailProc.running = false; sysDetailProc.running = true; } }
        }
        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface; radius: 10
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
        anchor.rect.y: mainBar.height - 525 // Adjusted for the extra row
        implicitWidth: 280
        implicitHeight: 520 // Increased to comfortably fit 6 rows + agenda
        visible: false
        color: "transparent"

        property date currentDate: new Date()
        readonly property int firstDayOffset: {
          let jsDay = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getDay();
          return jsDay === 0 ? 6 : jsDay - 1;
        }
        readonly property int daysInMonth: new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate()

        Connections {
          target: calendarPopup
          function onVisibleChanged() {
            if (calendarPopup.visible) {
              calendarPopup.currentDate = new Date();
              agendaProc.running = false;
              agendaProc.running = true;
            }
          }
        }

        Rectangle {
          anchors.fill: parent; color: root.theme.bgBase; border.width: 1; border.color: root.theme.bgSurface; radius: 10
          Column {
            anchors.fill: parent; anchors.margins: 15; spacing: 15

            Text {
              text: Qt.formatDateTime(calendarPopup.currentDate, "MMMM yyyy").toUpperCase();
              color: root.theme.textPrimary; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
            }

            // The Grid is now wrapped in an Item with a fixed height to prevent shifting
            Item {
              width: parent.width
              height: 240 // Fixed height to accommodate 7 total rows (Header + 6 weeks)
              anchors.horizontalCenter: parent.horizontalCenter

              GridLayout {
                id: calendarGrid
                anchors.fill: parent
                columns: 7
                rowSpacing: 10
                columnSpacing: 8

                // Header Row
                Repeater {
                  model: ["M", "T", "W", "T", "F", "S", "S"]
                  Text { text: modelData; color: root.theme.accentPrimary; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
                }

                // Empty space for start of month
                Repeater {
                  model: calendarPopup.firstDayOffset
                  Item { implicitWidth: 30; implicitHeight: 30 }
                }

                // The Days
                Repeater {
                  model: calendarPopup.daysInMonth
                  delegate: Rectangle {
                    implicitWidth: 30; implicitHeight: 30
                    radius: 4
                    readonly property int dayNum: index + 1
                    readonly property bool isToday: dayNum === new Date().getDate() &&
                    new Date().getMonth() === calendarPopup.currentDate.getMonth() &&
                    new Date().getFullYear() === calendarPopup.currentDate.getFullYear()
                    color: isToday ? root.theme.accentPrimary : "transparent"
                    Text {
                      anchors.centerIn: parent
                      text: dayNum
                      color: isToday ? root.theme.bgBase : root.theme.textPrimary
                      font.bold: isToday
                    }
                  }
                }

                // Filler to maintain 42 cells (6 weeks) if month is short
                Repeater {
                  model: 42 - (calendarPopup.firstDayOffset + calendarPopup.daysInMonth)
                  Item { implicitWidth: 30; implicitHeight: 30 }
                }
              }
            }

            Rectangle { width: parent.width; height: 1; color: root.theme.bgSurface }

            Item {
              width: parent.width
              height: 24

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Upcoming events"
                color: root.theme.accentPrimary
                //font.bold: true
                font.pixelSize: 16
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃭"
                color: root.theme.accentPrimary
                font.pixelSize: 22

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                    p.command = ["kitty", "--class" , "calendar", "-e", "ikhal"];
                    p.running = true;
                    calendarPopup.visible = false;
                  }
                }
              }
            }

            ScrollView {
              width: parent.width; height: 140; clip: true
              Text {
                width: parent.width
                text: root.agendaDetails
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: "Monospace"
                wrapMode: Text.Wrap
              }
            }
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
          Rectangle { anchors.fill: parent; color: root.theme.bgOverlay }
        }

        Rectangle {
          id: powerBox
          focus: true
          anchors.centerIn: parent
          width: 420; height: 120; radius: 12
          color: root.theme.bgBase; border.width: 2; border.color: root.theme.bgSurface
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
                color: pwrMouse.containsMouse ? root.theme.bgSurface : "transparent"
                Column {
                  anchors.centerIn: parent; spacing: 8
                  Text { text: modelData.i; color: modelData.c; font.pixelSize: 32; anchors.horizontalCenter: parent.horizontalCenter }
                  Text { text: modelData.t; color: root.theme.textPrimary; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
                MouseArea {
                  id: pwrMouse
                  anchors.fill: parent; hoverEnabled: true
                  onClicked: {
                    powerPopup.visible = false
                    let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
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

      // --- MAIN BAR CONTENT ---
      Item {
        anchors.fill: parent
        anchors.margins: 6

        Rectangle {
          width: 34; height: 34; radius: 8; color: root.theme.bgSurface; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
          Text { text: "󰀻"; anchors.centerIn: parent; color: root.theme.accentPrimary; font.pixelSize: 36 }
          MouseArea {
            anchors.fill: parent
            onClicked: {
              let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
              p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "controlcentre", "toggle"];
              p.running = true;
            }
          }
        }

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

        Column {
          anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width; spacing: 8
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

          Rectangle {
            width: 40; height: 45; radius: 8; color: root.theme.bgSurface
            Column {
              anchors.centerIn: parent; spacing: 1
              Text { text: "CPU"; color: root.theme.accentPrimary; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: SystemInfo.cpuUsage; font.pixelSize: 11; color: parseFloat(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: root.currentTemp; font.pixelSize: 11; color: parseInt(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea { anchors.fill: parent; onClicked: cpuPopup.visible = !cpuPopup.visible }
          }

          Row {
            spacing: 1; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
              width: 22; height: 22; radius: 6
              color: root.numLockActive ? root.theme.bgSelected : "transparent"
              border.width: 1; border.color: root.numLockActive ? root.theme.accentPrimary : root.theme.bgSurface
              Text { anchors.centerIn: parent; text: "1"; font.pixelSize: 13; font.bold: true; color: root.numLockActive ? "#FFFFFF" : root.theme.textMuted }
            }
            Rectangle {
              width: 22; height: 22; radius: 6
              color: root.capsLockActive ? root.theme.bgSelected : "transparent"
              border.width: 1; border.color: root.capsLockActive ? root.theme.accentPrimary : root.theme.bgSurface
              Text { anchors.centerIn: parent; text: "A"; font.pixelSize: 13; font.bold: true; color: root.capsLockActive ? "#FFFFFF" : root.theme.textMuted }
            }
          }

          Column {
            spacing: 2; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
              width: 32; height: 26; radius: 16; color: root.theme.bgSurface
              Text { anchors.centerIn: parent; text: "󰃠"; color: root.theme.accentOrange; font.pixelSize: 22 }
              MouseArea {
                anchors.fill: parent
                onWheel: (wheel) => {
                  let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                  p.command = wheel.angleDelta.y < 0 ? ["brightnessctl", "set", "5%+"] : ["brightnessctl", "set", "5%-"];
                  p.running = true;
                }
              }
            }
            Rectangle {
              width: 32; height: 26; radius: 16; color: root.theme.bgSurface
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

          Column {
            spacing: 4; anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
              model: SystemTray.items
              IconImage {
                source: modelData.icon !== "" ? modelData.icon : "network-wireless"
                implicitSize: 20
                MouseArea {
                  anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onClicked: (mouse) => {
                    if (modelData.id.toLowerCase().includes("network") || modelData.id.toLowerCase().includes("nm-applet")) {
                      let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                      p.command = ["kitty", "--class", "nmtui-terminal", "-e", "nmtui"];
                      p.running = true;
                    } else {
                      if (mouse.button === Qt.RightButton) modelData.secondaryActivate();
                      else modelData.activate();
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            width: 46; height: 24; radius: 8; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: Time.timeString.substring(0, 5); color: root.theme.textPrimary; font.pixelSize: 14; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: calendarPopup.visible = !calendarPopup.visible }
          }

          // Rectangle {
          //   width: 34; height: 20; radius: 10; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
          //   Text { anchors.centerIn: parent; text: "⏻"; color: "#fb4934"; font.pixelSize: 18 }
          //   MouseArea { anchors.fill: parent; onClicked: powerPopup.visible = !powerPopup.visible }
          // }
        }
      }
    }
  }
}
