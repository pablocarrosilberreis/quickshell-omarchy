import QtQuick

// System resources bar widget: CPU% · temp° · RAM%  (color-coded by load)
BarButton {
  id: root
  pad: 8

  color: {
    if (SysInfoState.cpu >= 80 || SysInfoState.ramPct >= 85
        || (SysInfoState.cpuTemp > 0 && SysInfoState.cpuTemp >= 80))
      return Theme.activeRed
    if (SysInfoState.cpu >= 60 || SysInfoState.ramPct >= 70
        || (SysInfoState.cpuTemp > 0 && SysInfoState.cpuTemp >= 70))
      return Theme.warning
    return Theme.foreground
  }

  text: {
    var s = Glyphs.cpu + "  " + SysInfoState.cpu + "%"
    if (SysInfoState.cpuTemp > 0) s += "  " + SysInfoState.cpuTemp + "°"
    return s
  }

  onHoveredChanged: {
    if (hovered) {
      SysInfoState.anchorX = root.mapToItem(null, 0, 0).x
      SysInfoState.anchorW = root.width
      SysInfoState.show()
    } else {
      SysInfoState.hide()
    }
  }
}
