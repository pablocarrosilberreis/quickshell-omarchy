import QtQuick
import Quickshell.Io

// custom/voxtype: streams voxtype status (idle/recording/transcribing).
// NOTE: `voxState` (not `state`, which is a built-in Item property).
// NOTE: run under `setsid` — omarchy-voxtype-status does `trap 'kill 0' EXIT`,
// which would otherwise kill QuickShell's whole process group.
BarButton {
  id: root
  pad: 7
  property string voxState: "idle"

  text: voxState === "recording" ? Glyphs.voxRecording
      : voxState === "transcribing" ? Glyphs.voxTranscribing
      : Glyphs.voxIdle
  color: voxState === "recording" ? Theme.activeRed : Theme.foreground

  leftCmd: "omarchy-voxtype-model"
  rightCmd: "omarchy-voxtype-config"

  Process {
    id: proc
    command: ["setsid", "omarchy-voxtype-status"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        try {
          var j = JSON.parse(line)
          root.voxState = j.alt || "idle"
          root.tooltipText = j.tooltip || ""
        } catch (e) {}
      }
    }
    onExited: restart.start()
  }

  // voxtype-status exits immediately when voxtype isn't installed; re-poll slowly.
  Timer { id: restart; interval: 3000; onTriggered: proc.running = true }
}
