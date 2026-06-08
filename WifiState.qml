pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool visible: false
  property real anchorX: 0
  property real anchorW: 0
  property bool wifiEnabled: false
  property bool scanning: false
  property string wifiIface: ""
  property var networks: []
  property var pendingNetwork: null

  readonly property var connected: networks.filter(function(n) { return n.connected })
  readonly property var saved:     networks.filter(function(n) { return !n.connected && n.saved })
  readonly property var nearby:    networks.filter(function(n) { return !n.connected && !n.saved })

  function show()   { KbLayoutState.hide(); BluetoothState.hide(); AudioState.hide(); SysInfoState.hide(); root.visible = true; networkPoll.run() }
  function hide()   { root.visible = false }
  function toggle() { root.visible ? hide() : show() }

  function connect(ssid) {
    // Optimistic UI: mark as connected immediately
    root.networks = root.networks.map(function(n) {
      return Object.assign({}, n, { connected: n.ssid === ssid, saved: n.ssid === ssid ? true : n.saved })
    })
    Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid])
    fastRefresh.restart()
  }

  function promptPassword(network) {
    root.pendingNetwork = network
  }

  function connectWithPassword(ssid, password) {
    root.pendingNetwork = null
    // Optimistic UI
    root.networks = root.networks.map(function(n) {
      return Object.assign({}, n, { connected: n.ssid === ssid, saved: n.ssid === ssid ? true : n.saved })
    })
    Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid, "password", password])
    fastRefresh.restart()
  }

  function cancelPassword() {
    root.pendingNetwork = null
  }

  function forget(ssid) {
    Quickshell.execDetached(["nmcli", "connection", "delete", "id", ssid])
    root.networks = root.networks.filter(function(n) { return n.ssid !== ssid })
  }

  function openSettings() {
    root.hide()
    Quickshell.execDetached(["omarchy-launch-wifi"])
  }

  function disconnect() {
    root.networks = root.networks.map(function(n) {
      return Object.assign({}, n, { connected: false })
    })
    if (root.wifiIface)
      Quickshell.execDetached(["nmcli", "device", "disconnect", root.wifiIface])
    fastRefresh.restart()
  }

  function toggleWifi() {
    root.wifiEnabled = !root.wifiEnabled
    Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "on" : "off"])
    if (root.wifiEnabled) refreshTimer.restart()
    else root.networks = []
  }

  function scan() {
    root.scanning = true
    Quickshell.execDetached(["nmcli", "device", "wifi", "rescan"])
    scanTimer.restart()
  }

  Poll {
    id: networkPoll
    immediate: true
    active: root.visible   // network list only needed while the popup is open
    interval: 8000
    command: ["omarchy-wifi-status"]
    onUpdated: (out) => {
      try {
        var d = JSON.parse(out.trim())
        root.wifiEnabled = d.enabled === true
        root.wifiIface   = d.iface || ""
        root.networks    = d.networks || []
      } catch (e) {}
    }
  }

  Timer {
    id: scanTimer
    interval: 4000
    onTriggered: {
      root.scanning = false
      networkPoll.run()
    }
  }

  // Polls every 2s up to 6 times after a connect/disconnect action
  Timer {
    id: fastRefresh
    interval: 2000
    repeat: true
    property int ticks: 0
    onTriggered: {
      networkPoll.run()
      ticks++
      if (ticks >= 6) { running = false; ticks = 0 }
    }
    onRunningChanged: if (running) ticks = 0
  }
}
