pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool visible: false
  property real anchorX: 0
  property real anchorW: 0
  property bool powered: false
  property bool scanning: false
  property var devices: []
  property bool _pendingPower: false

  // Derived lists — connected, known (not connected), nearby (discovered during scan)
  readonly property var connected: devices.filter(function(d) { return d.connected === true || d.connected === 1 })
  readonly property var known:     devices.filter(function(d) { return !(d.connected === true || d.connected === 1) && d.paired })
  readonly property var nearby:    devices.filter(function(d) { return !(d.connected === true || d.connected === 1) && !d.paired })

  onVisibleChanged: { if (!visible) stopScan() }
  onPoweredChanged: {
    if (!powered) { stopScan(); root.devices = root.devices.filter(function(d) { return d.paired }) }
    else refresh()
  }

  function show()   { KbLayoutState.hide(); WifiState.hide(); AudioState.hide(); SysInfoState.hide(); root.visible = true }
  function hide()   { root.visible = false }
  function toggle() { root.visible ? hide() : show() }

  function startScan() {
    Quickshell.execDetached(["bash", "-c",
      "kill $(cat /tmp/omarchy-bt-scan.pid 2>/dev/null) 2>/dev/null; omarchy-bluetooth-scan"])
    root.scanning = true
    devicePoll.interval = 2000
  }

  function stopScan() {
    Quickshell.execDetached(["bash", "-c",
      "kill $(cat /tmp/omarchy-bt-scan.pid 2>/dev/null) 2>/dev/null"])
    // Remove unpaired (nearby) devices from list when scan stops
    root.devices = root.devices.filter(function(d) { return d.paired })
    root.scanning = false
    devicePoll.interval = 3000
  }

  function connect(mac) {
    _setPaired(mac, true)
    _setConnected(mac, true)
    Quickshell.execDetached(["bash", "-c",
      "bluetoothctl pair '" + mac + "' ; bluetoothctl connect '" + mac + "'"])
    refreshTimer.restart()
  }

  function disconnect(mac) {
    _setConnected(mac, false)
    Quickshell.execDetached(["bluetoothctl", "disconnect", mac])
    refreshTimer.restart()
  }

  function remove(mac) {
    root.devices = root.devices.filter(function(d) { return d.mac !== mac })
    Quickshell.execDetached(["bluetoothctl", "remove", mac])
  }

  function togglePower() {
    root.powered = !root.powered
    root._pendingPower = true
    Quickshell.execDetached(["bluetoothctl", "power", root.powered ? "on" : "off"])
    powerConfirmTimer.restart()
  }

  function refresh() { devicePoll.run() }

  function _setConnected(mac, val) {
    root.devices = root.devices.map(function(d) {
      return d.mac === mac ? { mac: d.mac, name: d.name, connected: val, paired: d.paired } : d
    })
  }

  function _setPaired(mac, val) {
    root.devices = root.devices.map(function(d) {
      return d.mac === mac ? { mac: d.mac, name: d.name, connected: d.connected, paired: val } : d
    })
  }

  // Poll is the single source of truth for device state
  Poll {
    id: devicePoll
    immediate: true
    active: root.visible   // device list only needed while the popup is open
    interval: 3000
    command: ["omarchy-bluetooth-devices"]
    onUpdated: (out) => {
      if (root._pendingPower) return
      try {
        var d = JSON.parse(out)
        root.powered = d.powered === true
        var fresh = d.devices || []
        // Keep nearby (unpaired, scan-discovered) devices that aren't in the fresh list
        var nearbyKept = root.devices.filter(function(dev) {
          return !dev.paired && !fresh.some(function(f) { return f.mac === dev.mac })
        })
        root.devices = fresh.concat(nearbyKept)
      } catch (e) {}
    }
  }

  // Real-time monitor: only used to discover new nearby devices during scan,
  // so it only needs to run while the popup is open.
  Process {
    id: btMonitor
    command: ["bluetoothctl"]
    running: root.visible
    stdout: SplitParser {
      onRead: (line) => {
        var s = line.replace(/\x1b\[[0-9;]*[mGKHF]/g, "").replace(/[\r\[\]]/g, " ").trim()

        // New device during scan only
        var nm = s.match(/NEW\s+Device\s+([0-9A-Fa-f:]{17})\s+(.+)/)
        if (nm && root.scanning) {
          var mac = nm[1], name = nm[2].trim()
          if (!root.devices.some(function(d) { return d.mac === mac }))
            root.devices = root.devices.concat([{ mac: mac, name: name, connected: false, paired: false }])
          return
        }

        // Device removed
        var dm = s.match(/DEL\s+Device\s+([0-9A-Fa-f:]{17})/)
        if (dm) { root.devices = root.devices.filter(function(d) { return d.mac !== dm[1] }); return }

        // Power state (only when not in pending toggle)
        var pm = s.match(/CHG\s+Controller.+Powered:\s+(yes|no)/)
        if (pm && !root._pendingPower) { root.powered = pm[1] === "yes"; return }

        // Discovering state
        var disc = s.match(/CHG\s+Controller.+Discovering:\s+(yes|no)/)
        if (disc) { root.scanning = disc[1] === "yes"; return }
      }
    }
  }

  Timer {
    id: powerConfirmTimer
    interval: 2000
    onTriggered: { root._pendingPower = false; root.refresh() }
  }

  Timer {
    id: refreshTimer
    interval: 3000
    onTriggered: root.refresh()
  }
}
