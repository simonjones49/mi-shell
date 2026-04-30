import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}

  IpcHandler {
    target: "launcher"
    function toggle(): void {
      launcherPanel.visible = !launcherPanel.visible
      if (launcherPanel.visible) {
        searchInput.text = ""
        resultsList.currentIndex = 0
        searchInput.forceActiveFocus()
      }
    }
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      const all = [...DesktopEntries.applications.values];
      const q = searchInput.text.trim().toLowerCase();
      if (q === "") return all.sort((a, b) => a.name.localeCompare(b.name));
      return all.filter(d =>
      (d.name && d.name.toLowerCase().includes(q)) ||
      (d.genericName && d.genericName.toLowerCase().includes(q))
      ).sort((a, b) => a.name.localeCompare(b.name));
    }
  }

  function launchApp(entry) {
    entry.execute();
    launcherPanel.visible = false;
  }

  PanelWindow {
    id: launcherPanel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }

    MouseArea {
      anchors.fill: parent
      onClicked: launcherPanel.visible = false
      Rectangle { anchors.fill: parent; color: root.theme.bgOverlay }
    }

    Rectangle {
      id: launcherBox
      anchors.centerIn: parent
      width: 500
      height: 480
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
          text: "  Applications"
          color: root.theme.accentPrimary
          font.pixelSize: 14
          font.family: "Hack Nerd Font"
          font.bold: true
        }

        // Search Bar
        Rectangle {
          Layout.fillWidth: true
          height: 44
          radius: 10
          color: root.theme.bgSurface
          border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
          border.width: 1

          TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            color: "#FFFFFF"
            font.pixelSize: 15
            font.family: "Hack Nerd Font"
            focus: true

            // Helpful placeholder
            Text {
              anchors.fill: parent
              text: "Search..."
              color: root.theme.textMuted
              font: parent.font
              verticalAlignment: Text.AlignVCenter
              visible: !parent.text && !parent.activeFocus
            }

            onTextChanged: resultsList.currentIndex = 0
            Keys.onEscapePressed: launcherPanel.visible = false
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                event.accepted = true;
                resultsList.incrementCurrentIndex();
              } else if (event.key === Qt.Key_Up) {
                event.accepted = true;
                resultsList.decrementCurrentIndex();
              } else if (event.key === Qt.Key_Return) {
                event.accepted = true;
                const entry = filteredApps.values[resultsList.currentIndex];
                if (entry) root.launchApp(entry);
              }
            }
          }
        }

        ListView {
          id: resultsList
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: filteredApps
          clip: true
          spacing: 4
          currentIndex: 0

          highlight: Rectangle {
            width: resultsList.width
            height: 44
            radius: 8
            color: root.theme.bgSelected
          }
          highlightFollowsCurrentItem: true
          highlightMoveDuration: 0 // Snappy movement to avoid the "ghosting" bar

          delegate: Item {
            id: delegateRoot
            width: resultsList.width
            height: 44
            readonly property bool isSelected: ListView.isCurrentItem

            Row {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 15

              IconImage {
                width: 32; height: 32
                anchors.verticalCenter: parent.verticalCenter
                source: Quickshell.iconPath(modelData.icon ?? "", true)
                opacity: isSelected ? 1.0 : 0.5
              }

              Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 60 // Prevent text from pushing out of bounds

                Text {
                  text: modelData.name ?? ""
                  color: isSelected ? "#FFFFFF" : root.theme.textSecondary
                  font.pixelSize: 16
                  font.family: "Hack Nerd Font"
                  font.bold: isSelected
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  text: modelData.genericName ?? ""
                  color: root.theme.textMuted
                  font.pixelSize: 10
                  visible: text !== "" && isSelected
                  elide: Text.ElideRight
                  width: parent.width
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: resultsList.currentIndex = index
              onClicked: root.launchApp(modelData)
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Text { text: " " + resultsList.count + " apps"; color: root.theme.textMuted; font.pixelSize: 10 }
          Item { Layout.fillWidth: true }
          Text { text: "esc to close "; color: root.theme.textMuted; font.pixelSize: 10 }
        }
      }
    }
  }
}
