pragma Singleton
import QtQuick
import Quickshell

// Shared state for the audio device picker popup.
Singleton {
  id: root

  property bool visible: false
  property real anchorX: 0
  property real anchorW: 0
  property var sinks: []
  property var sources: []

  function show()   { KbLayoutState.hide(); WifiState.hide(); BluetoothState.hide(); SysInfoState.hide(); root.visible = true; refresh() }
  function hide()   { root.visible = false }
  function toggle() { root.visible ? hide() : show() }

  function setDefaultSink(name) {
    root.sinks = root.sinks.map(function(s) {
      return { name: s.name, desc: s.desc, active: s.name === name }
    })
    var escaped = name.replace(/'/g, "'\\''")
    Quickshell.execDetached(["bash", "-c",
      "pactl set-default-sink '" + escaped + "'" +
      " && pactl list sink-inputs short | awk '{print $1}'" +
      " | xargs -I{} pactl move-sink-input {} '" + escaped + "'"])
  }

  function setDefaultSource(name) {
    root.sources = root.sources.map(function(s) {
      return { name: s.name, desc: s.desc, active: s.name === name }
    })
    var escaped = name.replace(/'/g, "'\\''")
    Quickshell.execDetached(["bash", "-c",
      "pactl set-default-source '" + escaped + "'" +
      " && pactl list source-outputs short | awk '{print $1}'" +
      " | xargs -I{} pactl move-source-output {} '" + escaped + "'"])
  }

  function refresh() { devicePoll.run() }

  Poll {
    id: devicePoll
    immediate: true
    active: root.visible   // device list only needed while the popup is open
    interval: 30000
    command: ["omarchy-audio-devices"]
    onUpdated: (out) => {
      try {
        var d = JSON.parse(out)
        root.sinks   = d.sinks   || []
        root.sources = d.sources || []
      } catch (e) {}
    }
  }
}
