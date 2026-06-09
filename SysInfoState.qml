pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  // 350 ms hide-delay so the mouse can cross the gap from the bar item into the
  // popup without it closing (mirrors MediaPlayerState).
  property bool _show: false
  readonly property bool visible: _show
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
    hideTimer.stop(); root._show = true
    // Fetch a full snapshot immediately so GPU/NVMe refresh on hover instead of
    // waiting for the next poll tick (visible is already true, so sysPoll's
    // command binding is the full one).
    sysPoll.run()
  }
  function hide()   { hideTimer.restart() }
  Timer { id: hideTimer; interval: 350; onTriggered: root._show = false }

  function applyData(out) {
    try {
      var d = JSON.parse(out.trim())
      root.cpu          = d.cpu      || 0
      root.ramPct       = d.ram_pct  || 0
      root.ramUsed      = d.ram_used  || 0
      root.ramTotal     = d.ram_total || 0
      root.cpuTemp      = d.cpu_temp != null ? d.cpu_temp : -1
      // GPU usage / VRAM / GPU temp / NVMe temp only come in the full (non
      // --light) snapshot. The idle bar poll uses --light, so keep the last
      // known values cached instead of blanking them — the popup shows them
      // immediately on hover, then they refresh while it stays open.
      if (d.gpu            != null) root.gpu          = d.gpu
      if (d.gpu_vram_used  != null) root.gpuVramUsed  = d.gpu_vram_used
      if (d.gpu_vram_total != null) root.gpuVramTotal = d.gpu_vram_total
      if (d.gpu_temp       != null) root.gpuTemp      = d.gpu_temp
      if (d.nvme_temp      != null) root.nvmeTemp     = d.nvme_temp
    } catch (e) {}
  }

  Poll {
    id: sysPoll
    // Faster while the detailed popup is open; relaxed (and bar-only, via
    // --light) when it is closed — the bar only shows CPU% and temperature.
    interval: root.visible ? 1500 : 3000
    command: root.visible
      ? ["omarchy-sysinfo"]
      : ["omarchy-sysinfo", "--light"]
    onUpdated: (out) => root.applyData(out)
  }

  // One-shot full snapshot at startup to prime the GPU/NVMe cache, so the very
  // first hover shows them instantly instead of blank.
  Poll {
    interval: 99999999
    immediate: true
    command: ["omarchy-sysinfo"]
    onUpdated: (out) => root.applyData(out)
  }
}
