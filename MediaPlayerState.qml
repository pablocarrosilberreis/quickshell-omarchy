pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared MPRIS state + popup visibility for the media player bar item.
// Uses a 350 ms hide-delay so the mouse can travel from the bar to the popup.
Singleton {
  id: root

  // Popup visibility
  readonly property bool popupVisible: _show
  property bool _show: false
  property real anchorX: 0
  property real anchorW: 0
  function show() { hideTimer.stop(); _show = true }
  function hide() { hideTimer.restart() }
  Timer { id: hideTimer; interval: 350; onTriggered: root._show = false }

  // Player data
  property string playerName: ""
  property string playerStatus: ""
  property string artist: ""
  property string trackTitle: ""
  property string artUrl: ""
  property int positionSec: 0
  property int durationSec: 0

  // Tracks last known status per player to detect transitions.
  property var _playerStates: ({})

  readonly property bool active: (playerStatus === "Playing" || playerStatus === "Paused") && trackTitle.length > 0

  // Path to the app icon; empty string if not found.
  readonly property string appIconPath: {
    if (!playerName) return ""
    return "/usr/share/icons/hicolor/32x32/apps/" + playerName.toLowerCase() + ".png"
  }

  function fmt(s) {
    var m = Math.floor(s / 60), sec = s % 60
    return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
  }

  function _applyLine(p) {
    root.playerName   = p[0] || ""
    root.playerStatus = p[1] || ""
    root.artist       = p[2] || ""
    root.trackTitle   = p[3] || ""
    root.durationSec  = p[4] ? Math.round(parseInt(p[4]) / 1000000) : 0
    root.artUrl       = p[5] || ""
  }

  // Stream live metadata from all players
  Process {
    id: metaProc
    command: ["setsid", "playerctl", "-F", "-a", "metadata",
              "--format", "{{playerName}}|{{status}}|{{artist}}|{{title}}|{{mpris:length}}|{{mpris:artUrl}}"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        var p = line.trim().split("|")
        if (p.length < 4) return
        var name   = p[0] || ""
        var status = p[1] || ""

        var prev = root._playerStates[name] || ""
        var states = Object.assign({}, root._playerStates)
        states[name] = status
        root._playerStates = states

        var justStartedPlaying = status === "Playing" && prev !== "Playing"

        if (justStartedPlaying) {
          // Player transitioned to Playing → it takes priority.
          root._applyLine(p)
        } else if (name === root.playerName) {
          // State change on the displayed player → update it.
          root._applyLine(p)
        } else if (root.playerStatus !== "Playing") {
          // Nothing playing → most recently interacted player wins.
          root._applyLine(p)
        }
        // Else: non-priority player already playing → ignore.
      }
    }
    onExited: restartTimer.start()
  }
  Timer { id: restartTimer; interval: 3000; onTriggered: metaProc.running = true }

  property double _basePos: 0   // position (seconds) at last fetch
  property double _baseTime: 0  // Date.now()/1000 at last fetch

  // Increment locally every second while playing.
  Timer {
    interval: 1000
    running: root.playerStatus === "Playing"
    repeat: true
    onTriggered: {
      root.positionSec = Math.min(
        Math.round(root._basePos + (Date.now() / 1000 - root._baseTime)),
        root.durationSec > 0 ? root.durationSec : 999999)
    }
  }

  // Fetch real position on player switch or play event.
  onPlayerNameChanged:   { root.positionSec = 0; posProc.running = true }
  onPlayerStatusChanged: { if (root.playerStatus === "Playing") posProc.running = true }

  Process {
    id: posProc
    command: ["playerctl", "--player=" + root.playerName, "position"]
    stdout: StdioCollector { id: posCol }
    onExited: (code) => {
      if (code === 0) {
        root._basePos  = parseFloat(posCol.text.trim()) || 0
        root._baseTime = Date.now() / 1000
        root.positionSec = Math.round(root._basePos)
      }
    }
  }
}
