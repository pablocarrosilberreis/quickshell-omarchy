pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  property bool visible: false
  property real anchorX: 0
  property real anchorW: 0

  property int cpu: 0
  property int ramPct: 0
  property real ramUsed: 0
  property real ramTotal: 0
  property int gpu: -1
  property real gpuVramUsed: -1
  property real gpuVramTotal: -1
  property int cpuTemp: -1
  property int gpuTemp: -1
  property int nvmeTemp: -1

  function show() {
    WifiState.hide(); BluetoothState.hide(); AudioState.hide(); KbLayoutState.hide()
    root.visible = true
  }
  function hide()   { root.visible = false }
  function toggle() { root.visible ? hide() : show() }

  Poll {
    // Faster while the detailed popup is open; relaxed (and bar-only, via
    // --light) when it is closed — the bar only shows CPU% and temperature.
    interval: root.visible ? 1500 : 3000
    command: root.visible
      ? ["omarchy-sysinfo"]
      : ["omarchy-sysinfo", "--light"]
    onUpdated: (out) => {
      try {
        var d = JSON.parse(out.trim())
        root.cpu          = d.cpu      || 0
        root.ramPct       = d.ram_pct  || 0
        root.ramUsed      = d.ram_used  || 0
        root.ramTotal     = d.ram_total || 0
        root.gpu          = d.gpu          != null ? d.gpu          : -1
        root.gpuVramUsed  = d.gpu_vram_used  != null ? d.gpu_vram_used  : -1
        root.gpuVramTotal = d.gpu_vram_total != null ? d.gpu_vram_total : -1
        root.cpuTemp      = d.cpu_temp != null ? d.cpu_temp : -1
        root.gpuTemp      = d.gpu_temp != null ? d.gpu_temp : -1
        root.nvmeTemp     = d.nvme_temp != null ? d.nvme_temp : -1
      } catch (e) {}
    }
  }
}
