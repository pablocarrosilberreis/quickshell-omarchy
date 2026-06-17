import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick.Effects


// Bar: floating bubble groups on a transparent background.
Item {

  // ── Bar widgets (inline components) ─────────────────────────────────────
  component BarButton: Item {
    id: root
  
    property string text: ""
    property color color: Theme.foreground
    property string fontFamily: Theme.font
    property int fontSize: Theme.fontSize
    property int pad: 6
  
    property string tooltipText: ""
    property bool bgVisible: false
    // True while the pointer is over this module (for hover-driven popups).
    property alias hovered: mouse.containsMouse
    property string leftCmd: ""
    property string rightCmd: ""
    property string middleCmd: ""
    property string scrollUpCmd: ""
    property string scrollDownCmd: ""
  
    signal leftClicked()
    signal rightClicked()
    signal scrolledUp()
    signal scrolledDown()
  
    visible: root.text.length > 0
    implicitWidth: label.implicitWidth + 2 * pad
    implicitHeight: Theme.barHeight
  
    function exec(cmd) {
      if (cmd && cmd.length > 0)
        Quickshell.execDetached(["bash", "-c", cmd])
    }
  
    Rectangle {
      visible: root.bgVisible
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
      height: parent.height - 6
      radius: height / 2
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
      border.width: 1
      border.color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.18)
    }
  
    Text {
      id: label
      anchors.centerIn: parent
      anchors.verticalCenterOffset: 0
      text: root.text
      color: root.color
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      // NativeRendering: distance-field rendering fails for some fonts (e.g. the
      // tiny omarchy logo font), showing tofu boxes.
      renderType: Text.NativeRendering
    }
  
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      cursorShape: Qt.PointingHandCursor
  
      onClicked: (m) => {
        if (m.button === Qt.LeftButton) { root.exec(root.leftCmd); root.leftClicked() }
        else if (m.button === Qt.RightButton) { root.exec(root.rightCmd); root.rightClicked() }
        else if (m.button === Qt.MiddleButton) { root.exec(root.middleCmd) }
      }
      onWheel: (w) => {
        if (w.angleDelta.y > 0) { root.exec(root.scrollUpCmd); root.scrolledUp() }
        else if (w.angleDelta.y < 0) { root.exec(root.scrollDownCmd); root.scrolledDown() }
      }
  
      Tooltip {
        hostItem: root
        text: root.tooltipText
        visible: mouse.containsMouse && root.tooltipText.length > 0
      }
    }
  }
  component Tooltip: PopupWindow {
    id: pop
    property string text: ""
    property Item hostItem: null
  
    anchor.item: hostItem
    anchor.rect.x: hostItem ? (hostItem.width / 2 - pop.width / 2) : 0
    anchor.rect.y: hostItem ? hostItem.height + 4 : 0
  
    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight
    color: "transparent"
  
    Rectangle {
      id: bg
      anchors.fill: parent
      implicitWidth: label.implicitWidth + 14
      implicitHeight: label.implicitHeight + 8
      color: Theme.background
      border.color: Theme.accent
      border.width: 1
      radius: 4
  
      Text {
        id: label
        anchors.centerIn: parent
        text: pop.text
        color: Theme.foreground
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
  component OmarchyMenu: Item {
    id: root
    property int pad: 8
    property int iconSize: 15
    implicitWidth: iconSize + 2 * pad
    implicitHeight: Theme.barHeight
  
    Image {
      anchors.centerIn: parent
      width: root.iconSize
      height: root.iconSize
      sourceSize.width: root.iconSize * 2
      sourceSize.height: root.iconSize * 2
      source: Qt.resolvedUrl("assets/omarchy-mark.png")
      smooth: true
      layer.enabled: true
      layer.effect: MultiEffect {
        colorization: 1.0
        colorizationColor: Theme.foreground
        brightness: 1.0
      }
    }
  
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: (m) => {
        if (m.button === Qt.LeftButton) Quickshell.execDetached(["omarchy-menu"])
        else if (m.button === Qt.RightButton) Quickshell.execDetached(["xdg-terminal-exec"])
      }
      Tooltip {
        hostItem: root
        text: "Omarchy Menu\n\nSuper + Alt + Space"
        visible: mouse.containsMouse
      }
    }
  }
  component ActiveApp: BarButton {
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
  component Workspaces: Row {
    id: root
    spacing: 6
  
    function buildIds() {
      var ids = {1: true, 2: true, 3: true}
      var list = Hyprland.workspaces.values
      for (var j = 0; j < list.length; j++) {
        var id = list[j].id
        if (id > 0) ids[id] = true
      }
      var arr = []
      for (var k in ids) arr.push(parseInt(k))
      arr.sort(function(a, b) { return a - b })
      return arr
    }
  
    property var ids: buildIds()
  
    Connections {
      target: Hyprland.workspaces
      function onValuesChanged() { root.ids = root.buildIds() }
    }
  
    Repeater {
      model: root.ids
  
      delegate: Component {
        Item {
          id: ws
          required property int modelData
  
          readonly property bool focused: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.id === modelData
          readonly property bool exists: {
            var v = Hyprland.workspaces.values
            for (var i = 0; i < v.length; i++)
              if (v[i].id === modelData) return true
            return false
          }
  
          implicitWidth: 18
          implicitHeight: Theme.barHeight
  
          Text {
            anchors.centerIn: parent
            text: ws.exists ? "●" : "○"
            font.family: Theme.font
            font.pixelSize: ws.focused ? 20 : 17
            color: ws.focused ? Theme.accent : Theme.foreground
            opacity: ws.focused ? 1.0 : ws.exists ? 0.7 : 0.3
            renderType: Text.NativeRendering
          }
  
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("workspace", "" + modelData)
          }
        }
      }
    }
  }
  component MediaPlayer: Item {
    id: root
  
    visible: MediaPlayerState.active
    implicitWidth: MediaPlayerState.active ? (row.implicitWidth + 22) : 0
    implicitHeight: Theme.barHeight
    clip: true
  
    Row {
      id: row
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: -8
      spacing: 7
  
      // App icon — falls back to a music note glyph when no icon is found
      Item {
        width: 15; height: 15
        anchors.verticalCenter: parent.verticalCenter
  
        Image {
          id: appIcon
          anchors.fill: parent
          source: MediaPlayerState.appIconPath
          fillMode: Image.PreserveAspectFit
          visible: status === Image.Ready
          smooth: true
        }
        Text {
          anchors.centerIn: parent
          text: "♫"
          font.family: Theme.font
          font.pixelSize: 10
          color: Theme.foreground
          opacity: 0.6
          visible: appIcon.status !== Image.Ready
          renderType: Text.NativeRendering
        }
      }
  
      Text {
        text: MediaPlayerState.trackTitle
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        color: Theme.foreground
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 180)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        renderType: Text.NativeRendering
      }
    }
  
    HoverHandler {
      onHoveredChanged: {
        if (hovered) {
          MediaPlayerState.anchorX = root.mapToItem(null, 0, 0).x
          MediaPlayerState.anchorW = root.width
          MediaPlayerState.show()
        } else {
          MediaPlayerState.hide()
        }
      }
    }
  }
  component Clock: Item {
    id: root
    property int pad: 10
    property var now: new Date()
    property string weatherText: ""
  
    implicitWidth: row.implicitWidth + 2 * pad
    implicitHeight: Theme.barHeight
  
    Row {
      id: row
      anchors.centerIn: parent
      anchors.verticalCenterOffset: 1
      spacing: 7
  
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.now, "ddd d")
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.foreground
        opacity: 0.55
        renderType: Text.NativeRendering
      }
  
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.now, "HH:mm")
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground
        renderType: Text.NativeRendering
      }
  
      Text {
        id: weatherLabel
        anchors.verticalCenter: parent.verticalCenter
        text: root.weatherText
        visible: root.weatherText.length > 0
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.foreground
        opacity: 0.55
        renderType: Text.NativeRendering
  
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["bash", "-c",
            "notify-send -u low \"$(omarchy-weather-status)\""])
        }
      }
    }
  
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-tz-select"])
      onContainsMouseChanged: {
        if (containsMouse) {
          CalendarState.anchorX = root.mapToItem(null, 0, 0).x
          CalendarState.anchorW = root.width
          CalendarState.show()
        } else {
          CalendarState.hide()
        }
      }
    }
  
    Timer {
      interval: 1000
      running: true
      repeat: true
      onTriggered: root.now = new Date()
    }
  
    Poll {
      interval: 60000
      command: ["omarchy-weather-bar"]
      onUpdated: (out) => {
        try { root.weatherText = JSON.parse(out).text || "" }
        catch (e) { root.weatherText = "" }
      }
    }
  }
  component UpdateIndicator: BarButton {
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
  component Voxtype: BarButton {
    id: root
    pad: 7
    property string voxState: "idle"
  
    text: voxState === "recording" ? Glyphs.voxRecording
        : voxState === "transcribing" ? Glyphs.voxTranscribing
        : Glyphs.voxIdle
    color: voxState === "recording" ? Theme.activeRed : Theme.foreground
  
    leftCmd: "omarchy-voxtype-model"
    rightCmd: "omarchy-voxtype-config"
  
    Process {
      id: proc
      command: ["setsid", "omarchy-voxtype-status"]
      running: true
      stdout: SplitParser {
        onRead: (line) => {
          try {
            var j = JSON.parse(line)
            root.voxState = j.alt || "idle"
            root.tooltipText = j.tooltip || ""
          } catch (e) {}
        }
      }
      onExited: restart.start()
    }
  
    // voxtype-status exits immediately when voxtype isn't installed; re-poll slowly.
    Timer { id: restart; interval: 3000; onTriggered: proc.running = true }
  }
  component ScriptIndicator: BarButton {
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
  component Tray: Row {
    id: root
    spacing: 14
  
    Repeater {
      model: SystemTray.items
  
      delegate: Item {
        id: entry
        required property var modelData
        width: 16
        height: Theme.barHeight
  
        Image {
          id: icon
          anchors.centerIn: parent
          width: 14
          height: 14
          sourceSize.width: 14
          sourceSize.height: 14
          smooth: true
          source: entry.modelData.icon
        }
  
        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: (m) => {
            if (m.button === Qt.LeftButton) {
              entry.modelData.activate()
            } else if (m.button === Qt.MiddleButton) {
              entry.modelData.secondaryActivate()
            } else if (m.button === Qt.RightButton && entry.modelData.hasMenu) {
              menuAnchor.open()
            }
          }
  
          Tooltip {
            hostItem: entry
            text: entry.modelData.tooltipTitle || entry.modelData.title || ""
            visible: mouse.containsMouse && (entry.modelData.tooltipTitle || entry.modelData.title)
          }
        }
  
        QsMenuAnchor {
          id: menuAnchor
          menu: entry.modelData.menu
          anchor.item: entry
          anchor.rect.y: entry.height
        }
      }
    }
  }
  component Volume: BarButton {
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
  component KbLayout: BarButton {
    id: root
    pad: 10
    text: KbLayoutState.currentLayout
    tooltipText: KbLayoutState.currentLayoutName
    onLeftClicked: {
      KbLayoutState.anchorX = root.mapToItem(null, 0, 0).x
      KbLayoutState.anchorW = root.width
      KbLayoutState.toggle()
    }
  }
  component Bluetooth: BarButton {
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
  component Network: BarButton {
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
  component SysInfo: BarButton {
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
  component Battery: BarButton {
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
  // Per-device battery readout for wireless peripherals (mouse, keyboard,
  // headset, AirPods…). Data comes from `omarchy-peripheral-batteries`, which
  // merges UPower, the Compx keyboard HID feature report, and headsetcontrol.
  component PeripheralBatteries: Row {
    id: root
    spacing: 2
    property var devs: []

    function iconFor(kind) {
      return kind === "mouse"    ? Glyphs.mouse
           : kind === "keyboard" ? Glyphs.keyboard
           : kind === "earbuds"  ? Glyphs.paHeadphone
           : kind === "headset"  ? Glyphs.paHeadset
           : Glyphs.batDefault[5]
    }

    Poll {
      command: ["omarchy-peripheral-batteries"]
      interval: 60000
      onUpdated: (out) => {
        try { root.devs = JSON.parse(out) }
        catch (e) { root.devs = [] }
      }
    }

    Repeater {
      model: root.devs
      delegate: BarButton {
        required property var modelData
        pad: 6
        text: (modelData.charging ? Glyphs.charging + " " : "")
            + root.iconFor(modelData.kind) + "  " + modelData.pct + "%"
        color: modelData.charging ? Theme.foreground
             : modelData.pct <= 10 ? Theme.activeRed
             : modelData.pct <= 20 ? Theme.warning
             : Theme.foreground
        tooltipText: modelData.label + ": " + modelData.pct + "%"
            + (modelData.charging ? " (cargando)" : "")
      }
    }
  }
  component Bubble: Item {
    id: root
    default property alias contents: inner.data
    property int hpad: 8
  
    implicitWidth: inner.implicitWidth > 0 ? inner.implicitWidth + 2 * hpad : 0
    implicitHeight: Theme.barHeight
    visible: inner.implicitWidth > 0
  
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      height: parent.height - 6
      radius: height / 2
      color: Qt.darker(Theme.background, 1.8)
    }
  
    Row {
      id: inner
      anchors.centerIn: parent
      spacing: 2
    }
  }

  id: bar
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH")
    || (Quickshell.env("HOME") + "/.local/share/omarchy")

  MouseArea {
    anchors.fill: parent
    z: -1
    onClicked: { KbLayoutState.hide(); WifiState.hide(); BluetoothState.hide(); AudioState.hide(); SysInfoState.hide() }
  }

  // ── LEFT ──────────────────────────────────────────────────────────────────
  Row {
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    // Menu + active app
    Bubble {
      OmarchyMenu {}
      ActiveApp {}
    }

    // Workspaces
    Bubble { hpad: 4; Workspaces {} }

    // Media player (hidden when nothing is playing)
    Bubble { MediaPlayer {} }
  }

  // ── CENTER ────────────────────────────────────────────────────────────────
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    // Clock + weather + script indicators
    Bubble {
      Clock {}
      UpdateIndicator {}
      Voxtype {}
      ScriptIndicator {
        scriptPath: bar.omarchyPath + "/default/waybar/indicators/screen-recording.sh"
        clickCmd: "omarchy-capture-screenrecording"
      }
      ScriptIndicator {
        scriptPath: bar.omarchyPath + "/default/waybar/indicators/idle.sh"
        clickCmd: "omarchy-toggle-idle"
      }
      ScriptIndicator {
        scriptPath: bar.omarchyPath + "/default/waybar/indicators/notification-silencing.sh"
        clickCmd: "omarchy-toggle-notification-silencing"
      }
    }
  }

  // ── RIGHT ─────────────────────────────────────────────────────────────────
  Row {
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Bubble { Tray {} }
    Bubble { Volume {} }
    Bubble { KbLayout {} }
    Bubble { Bluetooth {} }
    Bubble { Network {} }
    Bubble { SysInfo {} }
    Bubble { PeripheralBatteries {} }
    Bubble { Battery {} }
  }
}

