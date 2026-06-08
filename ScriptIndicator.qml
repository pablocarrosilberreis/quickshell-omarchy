// Generic status indicator backed by an omarchy json script
// (screen-recording / idle / notification-silencing). Hidden when text empty;
// turns red when class == "active".
BarButton {
  id: root
  pad: 5
  fontSize: 10
  property string scriptPath: ""
  property string clickCmd: ""
  property bool active: false

  color: active ? Theme.activeRed : Theme.foreground
  leftCmd: clickCmd

  Poll {
    interval: 4000
    command: ["bash", root.scriptPath]
    onUpdated: (out) => {
      try {
        var j = JSON.parse(out)
        root.text = j.text || ""
        root.active = (j.class === "active")
        root.tooltipText = j.tooltip || ""
      } catch (e) { root.text = "" }
    }
  }
}
