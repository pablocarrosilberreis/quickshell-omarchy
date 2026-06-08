import QtQuick

// pulseaudio: icon + volume%; scroll to change, right-click mute.
BarButton {
  id: root
  pad: 8
  property int vol: 0
  property bool muted: false

  tooltipText: muted ? "Muted" : "Volume: " + vol + "%"
  onLeftClicked: {
    AudioState.anchorX = root.mapToItem(null, 0, 0).x
    AudioState.anchorW = root.width
    AudioState.toggle()
  }
  rightCmd: "pamixer -t"
  scrollUpCmd: "pamixer -i 5"
  scrollDownCmd: "pamixer -d 5"

  color: muted ? Theme.activeRed : Theme.foreground
  text: {
    var icon = muted ? Glyphs.paMutedX : Glyphs.paDefault[vol >= 66 ? 2 : vol >= 33 ? 1 : 0]
    return icon + "  " + (muted ? "Muted" : vol + "%")
  }

  // Delay so pamixer finishes before we read the new value
  Timer {
    id: refreshDelay
    interval: 150
    onTriggered: poll.run()
  }

  onScrolledUp:   refreshDelay.restart()
  onScrolledDown: refreshDelay.restart()
  onRightClicked: refreshDelay.restart()

  Poll {
    id: poll
    interval: 1500
    command: ["bash", "-c", "echo \"$(pamixer --get-volume 2>/dev/null) $(pamixer --get-mute 2>/dev/null)\""]
    onUpdated: (out) => {
      var p = out.trim().split(/\s+/)
      root.vol = parseInt(p[0] || "0")
      root.muted = (p[1] === "true")
    }
  }
}
