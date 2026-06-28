import QtQuick

// Swap 'QtObject' out for 'Item' right here
Item {
  id: masterTimer

  property int secondsPassed: 0

  signal tick1s()
  signal tick5s()
  signal tick30s()
  signal tick60s()
  signal tick5m()

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: {
      masterTimer.secondsPassed++;

      masterTimer.tick1s();

      if (masterTimer.secondsPassed % 5 === 0) {
        masterTimer.tick5s();
      }

      if (masterTimer.secondsPassed % 30 === 0) {
        masterTimer.tick30s();
      }

      if (masterTimer.secondsPassed % 60 === 0) {
        masterTimer.tick60s();
      }

      if (masterTimer.secondsPassed % 300 === 0) {
        masterTimer.tick5m();
      }

      if (masterTimer.secondsPassed >= 3600) {
        masterTimer.secondsPassed = 0;
      }
    }
  }
}
