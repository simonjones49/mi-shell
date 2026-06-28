import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Column {
  id: dockRoot

  // --- PASS-THROUGH PROPERTIES FROM BAR ---
  property var theme
  property var niriWindows
  property int itemWidth
  property int itemHeight
  property int iconSize

  spacing: 6

  // Fixed application mappings for accurate icon lookups
  property var pinnedApps: [
    { id: "qutebrowser", icon: "web-browser", exec: "qutebrowser.sh" },
    { id: "org.kde.dolphin", icon: "org.kde.dolphin", exec: "dolphin" },
    { id: "org.kde.kate", icon: "kate", exec: "kate" }
  ]

  // Loose-matching helper to connect app window strings with system launchers
  function windowMatchesApp(winAppId, pinnedId) {
    if (!winAppId || !pinnedId) return false;
    let w = winAppId.toLowerCase();
    let p = pinnedId.toLowerCase();
    return w === p || w.includes(p) || p.includes(w);
  }

  function resolveIcon(appId) {
    if (!appId) return "application-x-executable";
    let id = appId.toLowerCase();
    const iconMap = {
      "kitty": "utilities-terminal",
      "org.qutebrowser.qutebrowser": "qutebrowser",
      "qutebrowser": "qutebrowser",
      "org.kde.kate": "kate",
      "kate": "kate",
      "nautilus": "system-file-manager",
      "org.kde.dolphin": "org.kde.dolphin",
      "dolphin": "org.kde.dolphin",
      "aerc": "email",
      "khal": "calendar",
      "endcord": "discord",
      "watch-videos": "video-x-generic",
      "com.system76.cosmicsettings": "com.system76.CosmicSettings"
    };
    if (iconMap[id]) return iconMap[id];
    if (id.includes(".")) {
      let parts = id.split(".");
      return parts[parts.length - 1];
    }
    return id;
  }

  // 1. PINNED APPLICATIONS
  Repeater {
    model: dockRoot.pinnedApps
    delegate: Item {
      width: dockRoot.itemWidth; height: dockRoot.itemHeight; anchors.horizontalCenter: parent.horizontalCenter

      property var runningWin: {
        let list = dockRoot.niriWindows;
        for (let i = 0; i < list.length; i++) {
          if (dockRoot.windowMatchesApp(list[i].app_id, modelData.id)) {
            return list[i];
          }
        }
        return null;
      }
      property bool isRunning: runningWin !== null
      property bool isFocused: runningWin ? runningWin.is_focused : false

      opacity: isRunning ? 1.0 : 0.4

      Rectangle {
        anchors.centerIn: parent
        width: dockRoot.iconSize; height: dockRoot.iconSize; radius: 8
        color: isFocused ? dockRoot.theme.bgSurface : "transparent"
        border.width: isFocused ? 1 : 0
        border.color: dockRoot.theme.accentPrimary

        IconImage {
          anchors.fill: parent
          anchors.margins: 4
          source: "image://icon/" + modelData.icon
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          let p = Qt.createQmlObject('import Quickshell.Io; Process {}', dockRoot);
          if (isRunning) {
            p.command = ["niri", "msg", "action", "focus-window", "--id", runningWin.id.toString()];
          } else {
            p.command = [modelData.exec];
          }
          p.running = true;
        }
      }
    }
  }

  // 2. DYNAMIC UNPINNED RUNNING APPLICATIONS
  Repeater {
    model: dockRoot.niriWindows.filter(win => !dockRoot.pinnedApps.some(p => dockRoot.windowMatchesApp(win.app_id, p.id))).sort((a, b) => Number(a.id) - Number(b.id))
    delegate: Item {
      width: dockRoot.itemWidth; height: dockRoot.itemHeight; anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.centerIn: parent
        width: dockRoot.iconSize; height: dockRoot.iconSize; radius: 8
        color: modelData.is_focused ? dockRoot.theme.bgSurface : "transparent"
        border.width: modelData.is_focused ? 1 : 0
        border.color: dockRoot.theme.accentPrimary

        IconImage {
          anchors.fill: parent;
          anchors.margins: 4;
          source: "image://icon/" + dockRoot.resolveIcon(modelData.app_id)
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          let p = Qt.createQmlObject('import Quickshell.Io; Process {}', dockRoot);
          p.command = ["niri", "msg", "action", "focus-window", "--id", modelData.id.toString()];
          p.running = true;
        }
      }
    }
  }
}
