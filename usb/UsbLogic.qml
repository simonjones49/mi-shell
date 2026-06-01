import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: usbLogic
  property var driveList: []

  Process {
    id: lsblkProc
    // Added FSTYPE to the columns list
    command: ["lsblk", "-Jpno", "NAME,LABEL,MOUNTPOINT,SIZE,HOTPLUG,FSTYPE"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          let data = JSON.parse(text.trim());
          let flatDrives = [];

          // Helper function to extract partitions recursively
          function processDevice(dev, isHotplugParent = false) {
            // Inherit hotplug status from parent if necessary
            let isHotplug = dev.hotplug === true || dev.hotplug === "1" || isHotplugParent;

            if (dev.children && dev.children.length > 0) {
              dev.children.forEach(child => {
                processDevice(child, isHotplug);
              });
            } else if (isHotplug) {
              // Check if this leaf node is a locked LUKS container
              dev.encrypted = (dev.fstype === "crypto_LUKS");
              flatDrives.push(dev);
            }
          }

          if (data && data.blockdevices) {
            data.blockdevices.forEach(dev => {
              processDevice(dev);
            });
          }

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
