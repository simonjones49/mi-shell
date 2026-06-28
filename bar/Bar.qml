import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Scope {
  id: root

  // --- PROPERTIES ---
  property var theme
  property var niriWorkspaces: niriEngine.niriWorkspaces
  property var niriWindows: niriEngine.niriWindows

  // System engine bindings
  property string currentTemp: SystemInfo.cpuTemp
  property bool numLockActive: systemEngine.numLockActive
  property bool capsLockActive: systemEngine.capsLockActive
  property string batteryLevel: systemEngine.batteryLevel
  property string chargingStatus: systemEngine.chargingStatus
  property bool isSleepInhibited: systemEngine.isSleepInhibited

  property string sysDetails: "Loading stats..."
  property string agendaDetails: "No upcoming events."
  property date currentDate: new Date()

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
          "RAM   : " + lines[3] + "\n" +
          "Disk /: " + lines[4]   + "\n" +
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: mainBar
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; right: true }
      color: root.theme.bgBase

      // ========================================================
      // GLOBAL SIZING CONFIGURATION
      // ========================================================
      implicitWidth: 52
      property int itemWidth: 44
      property int itemHeight: 44
      property int iconSize: 44
      // ========================================================

      // --- POPUPS ---
      CalendarPopup {
        id: calendarPopup
        mainBarTarget: mainBar
        theme: root.theme
        currentDate: root.currentDate
        agendaDetails: root.agendaDetails
      }

      CpuPopup {
        id: cpuPopup
        mainBarTarget: mainBar
        theme: root.theme
        sysDetails: root.sysDetails
        sysDetailProcTarget: sysDetailProc
      }

      // --- POWER OVERLAY ---
      PowerPopup {
        id: powerPopup
        mainBarTarget: mainBar
        theme: root.theme
      }

      // --- MAIN BAR CONTENT ---
      Item {
        anchors.fill: parent
        anchors.margins: 6

        // --- TOP ALIGNED CONTENT BLOCK ---
        Column {
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: 6
          spacing: 8

          // --- Control Center Button ---
          Rectangle {
            width: 34; height: 34; radius: 8; color: root.theme.bgSurface
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

          // --- Media Player Button ---
          Rectangle {
            width: 34; height: 34; radius: 8; color: root.theme.bgSurface
            Text { text: "󰎆"; anchors.centerIn: parent; color: root.theme.accentPrimary; font.pixelSize: 30 }
            MouseArea {
              anchors.fill: parent
              onClicked: {
                let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "media", "toggle"];
                p.running = true;
              }
            }
          }

          // --- Sleep Inhibition (Coffee) Button ---
          Rectangle {
            width: 34; height: 34; radius: 8
            color: root.theme.bgSurface

            Text {
              text: "󰅶"
              anchors.centerIn: parent
              color: root.isSleepInhibited ? root.theme.accentPrimary : root.theme.textMuted
              font.pixelSize: 24
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                p.command = ["mi-caffeine"];
                p.running = true;
                systemEngine.triggerIdleCheck();
              }
            }
          }
        }

        // --- APPLICATION DOCK SECTION ---
        AppDock {
          y: 320
          width: parent.width
          theme: root.theme
          niriWindows: root.niriWindows
          itemWidth: mainBar.itemWidth
          itemHeight: mainBar.itemHeight
          iconSize: mainBar.iconSize
        }

        // --- BOTTOM ALIGNED CONTENT BLOCK ---
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
                id: wsRepeater
                model: root.niriWorkspaces // FIX: Changed from niriEngine.niriWorkspaces

                Rectangle {
                  width: 10
                  height: modelData.is_focused ? 22 : 10
                  radius: 5
                  color: modelData.is_focused ? root.theme.accentPrimary : root.theme.textPrimary
                  anchors.horizontalCenter: parent.horizontalCenter
                }
              }
            }
          }

          // --- CPU Block ---
          Rectangle {
            width: 40; height: 45; radius: 8; color: root.theme.bgSurface
            anchors.horizontalCenter: parent.horizontalCenter
            Column {
              anchors.centerIn: parent; spacing: 1
              Text { text: "CPU"; color: root.theme.accentPrimary; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: SystemInfo.cpuUsage; font.pixelSize: 11; color: parseFloat(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: root.currentTemp; font.pixelSize: 11; color: parseInt(text) > 80 ? "#fb4934" : "#55aa00"; anchors.horizontalCenter: parent.horizontalCenter }
            }
            MouseArea { anchors.fill: parent; onClicked: cpuPopup.visible = !cpuPopup.visible }
          }

          // --- Battery Block ---
          Rectangle {
            visible: {
              if (!root.batteryLevel || root.batteryLevel === "" || root.batteryLevel === "0%")
                return false;

              let level = parseInt(root.batteryLevel.replace("%", ""));
              return level > 0 && level < 100;
            }
            width: 40; height: 26; radius: 8; color: root.theme.bgSurface
            anchors.horizontalCenter: parent.horizontalCenter
            Row {
              anchors.centerIn: parent; spacing: 2
              Text {
                font.family: "JetBrainsMono Nerd Font"
                text: (root.chargingStatus === "charging") ? "󱐋 " + root.batteryLevel : "  " + root.batteryLevel
                color: (root.chargingStatus === "charging") ? root.theme.accentPrimary : root.theme.textPrimary
                font.pixelSize: 13
              }
            }
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
              Text { anchors.centerIn: parent; text: "󰃠"; color: root.theme.accentPrimary; font.pixelSize: 22 }
              MouseArea {
                anchors.fill: parent
                onWheel: (wheel) => {
                  let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                  p.command = wheel.angleDelta.y < 0 ? ["brightnessctl", "set", "5%-"] : ["brightnessctl", "set", "5%+"];
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

          // --- USB Monitor Button ---
          Rectangle {
            visible: usbMonitor.driveList.length > 0
            width: 36; height: 20; radius: 16
            color: root.theme.bgSurface
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
              text: "󱊞"
              anchors.centerIn: parent
              color: root.theme.accentPrimary
              font.pixelSize: 20
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                let p = Qt.createQmlObject('import Quickshell.Io; Process {}', root);
                p.command = ["quickshell", "-c", "mi-shell", "ipc", "call", "usbpopupcomp", "toggle"];
                p.running = true;
              }
            }
          }

          // --- SYSTEM TRAY SECTION ---
          SysTray {
            theme: root.theme
          }

          Rectangle {
            width: 46; height: 24; radius: 8; color: root.theme.bgSurface; anchors.horizontalCenter: parent.horizontalCenter
            Text { anchors.centerIn: parent; text: Time.timeString.substring(0, 5); color: root.theme.textPrimary; font.pixelSize: 14; font.bold: true }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                // 1. Refresh the date object so the calendar displays the actual current day
                root.currentDate = new Date();

                // 2. Trigger the khal process to populate the agenda stream
                agendaProc.running = true;

                // 3. Toggle the popup window surface visibility
                calendarPopup.visible = !calendarPopup.visible;
              }
            }
          }
        }
      }
    }
  }
}
