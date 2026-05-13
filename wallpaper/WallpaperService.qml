pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property list<string> wallpapers: []
  property string currentWallpaper: ""
  property string backend: "swaybg"

  // Scan wallpaper directories
  Process {
    id: scanner
    command: ["sh", "-c",
    "find ~/Pictures/Wallpapers -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort -u | head -200"
    ]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const path = data.trim();
        if (path !== "") {
          root.wallpapers = [...root.wallpapers, path];
        }
      }
    }
  }

  // Load saved wallpaper path
  FileView {
    id: configFile
    path: Quickshell.env("HOME") + "/.config/quickshell/mi-shell/wallpaper.conf"
    onTextChanged: {
      const saved = configFile.text().trim();
      if (saved !== "") root.currentWallpaper = saved;
    }
  }

  Component.onCompleted: {
    scanner.running = true;
  }

  function rescan() {
    wallpapers = [];
    scanner.running = true;
  }

  function setWallpaper(path) {
    if (!path) return;
    currentWallpaper = path;

    // Reset the processes to ensure they can run again
    setProcess.running = false;
    saveProcess.running = false;

    // 1. Update and Run Set Process
    // We use "sh" as $0, so path becomes $1
    setProcess.command = ["sh", "-c", "pkill swaybg; swaybg -i \"$1\" -m fill", "sh", path];
    setProcess.running = true;

    // 2. Update and Run Save Process
    saveProcess.command = [
      "sh", "-c",
      'mkdir -p "$HOME/.config/quickshell/mi-shell" && printf "%s" "$1" > "$HOME/.config/quickshell/mi-shell/wallpaper.conf"',
      "sh",
      path
    ];
    saveProcess.running = true;
  }

  Process {
    id: setProcess
    command: []
    running: false
  }

  Process {
    id: saveProcess
    command: []
    running: false
  }
}
