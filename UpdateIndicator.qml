// custom/update: show update glyph only when an Omarchy update is available.
BarButton {
  id: root
  pad: 8
  fontSize: 10
  tooltipText: "Omarchy update available"
  leftCmd: "omarchy-launch-floating-terminal-with-presentation omarchy-update"

  Poll {
    interval: 21600000
    command: ["omarchy-update-available"]
    onUpdated: (out) => {
      root.text = (out.indexOf("update available") >= 0) ? Glyphs.update : ""
    }
  }
}
