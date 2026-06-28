import QtQuick
import Quickshell.Io

Item {
  id: niriEngine

  // 1. Declare the properties locally so they hold the state
  property var niriWindows: []
  property var niriWorkspaces: []

  // --- NIRI EVENT STREAM ENGINE ---
  Process {
    id: niriStream
    command: ["niri", "msg", "--json", "event-stream"]
    running: true

    onRunningChanged: {
      if (!running) startTimer.start();
    }

    stdout: SplitParser {
      onRead: (line) => {
        try {
          let event = JSON.parse(line.trim());

          if (event.WindowsChanged) {
            let wins = event.WindowsChanged.windows;
            // TWEAK: Point to niriEngine instead of root
            niriEngine.niriWindows = wins.filter(win => win.title !== "dropdown").map(win => {
              return {
                id: win.id,
                app_id: win.app_id || "",
                title: win.title || "",
                is_focused: win.is_focused || false
              };
            }).sort((a, b) => a.id - b.id);
          }

          if (event.WindowOpenedOrChanged) {
            let win = event.WindowOpenedOrChanged.window;
            if (win.title !== "dropdown") {
              let found = false;

              // TWEAK: Point to niriEngine instead of root
              let updated = niriEngine.niriWindows.map(w => {
                if (w.id === win.id) {
                  found = true;
                  return { id: win.id, app_id: win.app_id || "", title: win.title || "", is_focused: win.is_focused || false };
                }
                return {
                  id: w.id,
                  app_id: w.app_id,
                  title: w.title,
                  is_focused: win.is_focused ? false : w.is_focused
                };
              });

              if (!found) {
                updated.push({ id: win.id, app_id: win.app_id || "", title: win.title || "", is_focused: win.is_focused || false });
                if (win.is_focused) {
                  updated = updated.map(w => {
                    return { id: w.id, app_id: w.app_id, title: w.title, is_focused: w.id === win.id };
                  });
                }
              }
              niriEngine.niriWindows = updated.sort((a, b) => a.id - b.id);
            }
          }

          if (event.WindowClosed) {
            let closedId = event.WindowClosed.id;
            niriEngine.niriWindows = niriEngine.niriWindows.filter(w => w.id !== closedId);
          }

          if (event.WorkspacesChanged) {
            let ws = event.WorkspacesChanged.workspaces;
            let updatedWs = ws.map(w => {
              return {
                id: w.id,
                name: w.name || "",
                is_focused: w.is_focused || false
              };
            }).sort((a, b) => a.id - b.id);

            niriEngine.niriWorkspaces = []; // Force update
            niriEngine.niriWorkspaces = updatedWs;
          }

          if (event.WindowFocusChanged) {
            let focusedId = event.WindowFocusChanged.id;
            niriEngine.niriWindows = niriEngine.niriWindows.map(win => {
              return {
                id: win.id,
                app_id: win.app_id,
                title: win.title,
                is_focused: (win.id === focusedId)
              };
            });
          }

          if (event.WorkspaceActivated) {
            let focusedWsId = event.WorkspaceActivated.id;
            let updatedWs = niriEngine.niriWorkspaces.map(ws => {
              return {
                id: ws.id,
                name: ws.name,
                is_focused: (ws.id == focusedWsId)
              };
            });

            niriEngine.niriWorkspaces = []; // Force update notification
            niriEngine.niriWorkspaces = updatedWs;
          }
        } catch(e) {
          console.error("NiriEngine event parser error: ", e);
        }
      }
    }
  }

  Timer {
    id: startTimer
    interval: 2000
    repeat: false
    onTriggered: niriStream.running = true
  }

  Process {
    id: initFetch
    command: ["sh", "-c", "niri msg -j workspaces && echo '---SEP---' && niri msg -j windows"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          let parts = text.split('---SEP---');
          if (parts.length >= 2) {
            let ws = JSON.parse(parts[0].trim());
            let updatedWs = ws.map(w => {
              return { id: w.id, name: w.name || "", is_focused: w.is_focused || false };
            }).sort((a, b) => a.id - b.id);

            niriEngine.niriWorkspaces = []; // Clear first to force notification
            niriEngine.niriWorkspaces = updatedWs;
          }
        } catch(e) {}
      }
    }
  }
}
