// network: icon + SSID/ethernet label; left-click opens wifi popup.
BarButton {
  id: root
  pad: 8
  text: Glyphs.netDisconnected
  tooltipText: "Disconnected"
  onLeftClicked: {
    WifiState.anchorX = root.mapToItem(null, 0, 0).x
    WifiState.anchorW = root.width
    WifiState.toggle()
  }

  Poll {
    interval: 5000
    command: ["bash", "-c",
      "if nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2==\"ethernet\"&&$3==\"connected\"{f=1} END{exit !f}'; then echo 'eth\tEthernet'; " +
      "elif w=$(nmcli -t -f ACTIVE,SSID,SIGNAL device wifi 2>/dev/null | awk -F: '$1==\"yes\"{print;exit}') && [ -n \"$w\" ]; then " +
      "ssid=$(echo \"$w\"|cut -d: -f2); sig=$(echo \"$w\"|cut -d: -f3); " +
      "printf 'wifi\\t%s\\t%s\\n' \"$ssid\" \"$sig\"; " +
      "else echo 'down\t'; fi"]
    onUpdated: (out) => {
      var f = out.trim().split("\t")
      if (f[0] === "eth") {
        root.text = Glyphs.netEthernet + "  Ethernet"
        root.tooltipText = "Wired connection"
      } else if (f[0] === "wifi") {
        var s = parseInt(f[2] || "0")
        var idx = s >= 80 ? 4 : s >= 60 ? 3 : s >= 40 ? 2 : s >= 20 ? 1 : 0
        var ssid = f[1] || ""
        var label = ssid.length > 12 ? ssid.substring(0, 12) + "…" : ssid
        root.text = Glyphs.netWifi[idx] + "  " + label
        root.tooltipText = ssid + " (" + s + "%)"
      } else {
        root.text = Glyphs.netDisconnected
        root.tooltipText = "Disconnected"
      }
    }
  }
}
