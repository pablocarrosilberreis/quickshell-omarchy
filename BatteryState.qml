pragma Singleton
import QtQuick
import Quickshell

// Battery levels of wireless peripherals (mouse, keyboard, headset, AirPods…),
// fed by `omarchy-peripheral-batteries`. Drives the battery popup (Apple-style
// device list) and the bar bubble. The laptop battery itself comes straight
// from UPower.displayDevice in the widgets, not from here.
Singleton {
  id: root

  // 350 ms hide-delay so the pointer can cross the gap from the bar bubble into
  // the popup without it closing (mirrors SysInfoState).
  property bool _show: false
  readonly property bool visible: _show
  property real anchorX: 0
  property real anchorW: 0

  property var devs: []

  function show() {
    WifiState.hide(); BluetoothState.hide(); AudioState.hide()
    KbLayoutState.hide(); SysInfoState.hide()
    hideTimer.stop(); root._show = true
    poll.run()   // refresh on open
  }
  function hide() { hideTimer.restart() }
  Timer { id: hideTimer; interval: 350; onTriggered: root._show = false }

  // Batteries change over hours; poll slowly and rely on the on-open/on-hover
  // refresh (poll.run()) for freshness when actually looked at.
  Poll {
    id: poll
    interval: 300000
    command: ["omarchy-peripheral-batteries"]
    onUpdated: (out) => {
      try { root.devs = JSON.parse(out) }
      catch (e) { root.devs = [] }
    }
  }
}
