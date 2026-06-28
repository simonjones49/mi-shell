import QtQuick
import Quickshell.Io

Item {
  id: systemEngine

  // --- 1. Global State Properties (Aligned with Bar names) ---
  property bool numLockActive: false
  property bool capsLockActive: false
  property string cpuTemp: "--"
  property string batteryLevel: "..."
  property string chargingStatus: "discharging"
  property bool isSleepInhibited: false

  // Helper method allowing the coffee button to manually trigger a check
  function triggerIdleCheck() {
    idleProc.running = true;
  }

  // --- 2. The Master Timer Conductor ---
  Connections {
    target: masterTimer

    // Every 1 second: Check keyboard locks
    function onTick1s() {
      numLockCheck.running = true;
      capsLockCheck.running = true;
    }

    // Every 5 seconds: Check temperatures & idle state
    function onTick5s() {
      tempProc.running = true;
      idleProc.running = true;
    }

    // Every 30 seconds: Check battery status
    function onTick30s() {
      battProc.running = true;
      battStatusProc.running = true;
    }
  }

  // --- 3. The Working Processes ---
  Process {
    id: numLockCheck
    command: ["sh", "-c", "grep -q '1' /sys/class/leds/*::numlock/brightness && echo '1' || echo '0'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { systemEngine.numLockActive = (text.trim() === "1"); }
    }
  }

  Process {
    id: capsLockCheck
    command: ["sh", "-c", "grep -q '1' /sys/class/leds/*::capslock/brightness && echo '1' || echo '0'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { systemEngine.capsLockActive = (text.trim() === "1"); }
    }
  }

  Process {
    id: tempProc
    command: ["bash", "-c", "sensors | awk '/Core 0/ {print $3}'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { systemEngine.cpuTemp = text.trim(); }
    }
  }

  Process {
    id: battProc
    command: ["sh", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep 'percentage' | sed -e 's/percentage://' | sed -e 's/ //g'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { systemEngine.batteryLevel = text.trim(); }
    }
  }

  Process {
    id: battStatusProc
    command: ["/bin/sh", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep 'state' | sed -e 's/state://' | sed -e 's/ //g'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { systemEngine.chargingStatus = text.trim(); }
    }
  }

  Process {
    id: idleProc
    command: ["sh", "-c", "pgrep -x swayidle > /dev/null || echo 'INHIBITED'"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: { systemEngine.isSleepInhibited = text.includes("INHIBITED"); }
    }
  }
}
