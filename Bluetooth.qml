// bluetooth: icon + connected device name. Left-click opens device picker.
BarButton {
  id: root
  pad: 8

  onLeftClicked: {
    BluetoothState.anchorX = root.mapToItem(null, 0, 0).x
    BluetoothState.anchorW = root.width
    BluetoothState.toggle()
  }
  rightCmd: "bluetoothctl power " + (BluetoothState.powered ? "off" : "on")

  text: {
    if (!BluetoothState.powered) return Glyphs.btOff
    var c = BluetoothState.connected
    if (c.length === 0) return Glyphs.btOn
    var label = c[0].name.length > 12 ? c[0].name.substring(0, 12) + "…" : c[0].name
    return Glyphs.btConnected + "  " + label
  }

  tooltipText: {
    if (!BluetoothState.powered) return "Bluetooth off"
    var c = BluetoothState.connected
    if (c.length === 0) return "Bluetooth on, no devices"
    return c.map(function(d) { return d.name }).join(", ")
  }
}
