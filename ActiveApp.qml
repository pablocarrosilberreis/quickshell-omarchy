import QtQuick
import Quickshell.Io

// Shows the focused window's app class, updated via Hyprland event socket.
// Hidden when no window is focused.
BarButton {
  id: root
  pad: 8
  text: ""
  tooltipText: ""

  function fmt(cls) {
    if (!cls || cls.length === 0) return ""
    var s = cls.charAt(0).toUpperCase() + cls.slice(1)
    return s.length > 22 ? s.substring(0, 22) + "…" : s
  }

  // Seed from hyprctl on startup
  Process {
    id: init
    command: ["bash", "-c", "hyprctl activewindow -j 2>/dev/null | " +
              "python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('initialClass',''))\""]
    running: true
    stdout: StdioCollector {
      id: initCol
    }
    onExited: root.text = root.fmt(initCol.text.trim())
  }

  // Listen for activewindow events on Hyprland socket2
  Process {
    id: evtProc
    command: ["bash", "-c",
      "sock=\"/run/user/$(id -u)/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock\"; " +
      "socat -U - UNIX-CONNECT:\"$sock\" 2>/dev/null | grep --line-buffered '^activewindow>>'"]
    running: true
    stdout: SplitParser {
      onRead: (line) => {
        // Format: activewindow>>class,title
        var data = line.replace(/^activewindow>>/, "")
        var cls = data.split(",")[0] || ""
        root.text = root.fmt(cls)
        root.tooltipText = data.split(",").slice(1).join(",")
      }
    }
    onExited: restartTimer.start()
  }
  Timer { id: restartTimer; interval: 2000; onTriggered: evtProc.running = true }
}
