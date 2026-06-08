import Quickshell.Services.UPower

// battery: icon + percentage; hidden on desktops without a battery.
BarButton {
  id: root
  pad: 8

  readonly property var dev: UPower.displayDevice
  readonly property bool present: dev && dev.isLaptopBattery
  readonly property int pct: dev ? Math.max(0, Math.min(100, Math.round(dev.percentage))) : 0
  readonly property bool charging: dev
    && (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge)
  readonly property bool full: dev
    && (dev.state === UPowerDeviceState.FullyCharged || pct >= 100)

  readonly property string batIcon: !present ? ""
    : full ? Glyphs.batFull
    : (charging ? Glyphs.batCharging : Glyphs.batDefault)[Math.min(9, Math.floor(pct / 10))]

  text: !present ? "" : (batIcon + "  " + pct + "%")

  color: (!charging && pct <= 10) ? Theme.activeRed
       : (!charging && pct <= 20) ? Theme.warning
       : Theme.foreground

  tooltipText: {
    if (!present) return ""
    var w = dev ? Math.abs(dev.changeRate).toFixed(0) : "0"
    return (charging ? (w + "W↑ ") : (w + "W↓ ")) + pct + "%"
  }

  leftCmd: "omarchy-menu power"
  rightCmd: "notify-send -u low \"$(omarchy-battery-status)\""
}
