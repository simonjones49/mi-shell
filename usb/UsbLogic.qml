import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: usbLogic
  property var driveList: []

  Process {
    id: lsblkProc
      command: ["lsblk", "-Jpno", "NAME,LABEL,MOUNTPOINT,SIZE,HOTPLUG"]
      stdout: StdioCollector {
        onStreamFinished: {
          try {
            let data = JSON.parse(text.trim());
            let flatDrives = [];

            data.blockdevices.forEach(dev => {
              // FIX: Use 'hotplug' instead of 'rm' to catch external SSDs
              // lsblk JSON can return "1" (string) or true (boolean)
              if (dev.hotplug === true || dev.hotplug === "1") {

                if (dev.children) {
                  // Add the partitions (e.g., sdb1, sdb2)
                  dev.children.forEach(child => {
                    // Carry over the name if the child name is shortened
                    flatDrives.push(child);
                  });
                } else {
                  // No partitions, add the raw device (e.g., sda)
                  flatDrives.push(dev);
                }
              }
            });
            usbLogic.driveList = flatDrives;
          } catch(e) {
            console.log("USB Logic Error: " + e);
            usbLogic.driveList = [];
          }
        }
    }
  }

  function refreshDrives() {
    lsblkProc.running = false;
    lsblkProc.running = true;
  }

  Timer {
    interval: 4000; running: true; repeat: true; triggeredOnStart: true
    onTriggered: refreshDrives()
  }
}
