import QtQuick
import Quickshell.Io

// Periodically runs a one-shot command and emits its trimmed stdout.
// (For commands that stream continuously, use a Process+SplitParser directly.)
Item {
  id: root
  property var command: []
  property int interval: 3000
  property bool immediate: true
  // When false, the periodic timer stops (e.g. gate a popup-only poll to
  // its visibility). `run()` still works for one-shot manual refreshes.
  property bool active: true
  property string text: ""
  signal updated(string out)

  function run() {
    if (root.command.length > 0 && !proc.running)
      proc.running = true
  }

  Process {
    id: proc
    command: root.command
    stdout: StdioCollector { id: col }
    onExited: (code, status) => {
      // StdioCollector accumulates across runs — always use the last non-empty line
      var lines = col.text.split('\n').filter(function(l) { return l.trim().length > 0 })
      root.text = lines.length > 0 ? lines[lines.length - 1] : ""
      root.updated(root.text)
    }
  }

  Timer {
    interval: root.interval
    running: root.active
    repeat: true
    triggeredOnStart: root.immediate
    onTriggered: root.run()
  }
}
