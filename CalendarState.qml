pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared state for the calendar popup. Using a 350 ms hide-delay so the
// mouse can travel from the clock bubble to the popup without it closing.
Singleton {
  id: root
  readonly property bool visible: _show
  property bool _show: false
  property real anchorX: 0
  property real anchorW: 0

  property var weather: null

  function show() { hideTimer.stop(); _show = true; NotifState.dismissToast() }
  function hide() { hideTimer.restart() }

  Timer { id: hideTimer; interval: 350; onTriggered: root._show = false }

  Poll {
    interval: 1800000  // 30 min
    immediate: true
    command: ["omarchy-weather-forecast"]
    onUpdated: (out) => {
      try {
        var d = JSON.parse(out.trim())
        if (d && d.current) root.weather = d
      } catch(e) {}
    }
  }
}
