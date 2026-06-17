import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import QtQuick.Controls

// All bar popups + their row/section sub-components as flat inline
// components (referenced from shell.qml as Popups.<Name>). Never instantiated.
Item {

  component WifiNetworkRow: Item {
    id: row
  
    property string ssid: ""
    property int signal: 0
    property bool secured: false
    property bool connected: false
    property bool saved: false
  
    signal activate()
    signal forget()
  
    height: 30
    width: parent ? parent.width : 280
  
    HoverHandler { id: rowHover }
  
    readonly property int sigIdx: signal >= 80 ? 4 : signal >= 60 ? 3 : signal >= 40 ? 2 : signal >= 20 ? 1 : 0
  
    Rectangle {
      anchors.fill: parent
      color: row.connected
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
        : rowHover.hovered
          ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
          : "transparent"
    }
  
    // Active indicator
    Text {
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      text: "▶"
      font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
      color: Theme.accent
      visible: row.connected
      renderType: Text.NativeRendering
    }
  
    // Signal strength icon
    Text {
      id: sigIcon
      anchors { left: parent.left; leftMargin: 32; verticalCenter: parent.verticalCenter }
      text: Glyphs.netWifi[row.sigIdx]
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: row.connected ? Theme.accent : Theme.foreground
      opacity: row.connected ? 1.0 : (rowHover.hovered ? 1.0 : 0.7)
      renderType: Text.NativeRendering
    }
  
    // SSID
    Text {
      anchors {
        left: sigIcon.right; leftMargin: 6
        right: forgetBtn.visible ? forgetBtn.left : (lockIcon.visible ? lockIcon.left : parent.right)
        rightMargin: 6
        verticalCenter: parent.verticalCenter
      }
      text: row.ssid
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: row.connected ? Theme.accent : Theme.foreground
      opacity: row.connected ? 1.0 : (rowHover.hovered ? 1.0 : 0.8)
      elide: Text.ElideRight
      renderType: Text.NativeRendering
    }
  
    // Lock icon for secured networks not yet saved
    Text {
      id: lockIcon
      anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
      text: ""
      font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
      color: Theme.foreground; opacity: 0.35
      visible: row.secured && !row.connected && !row.saved && !rowHover.hovered
      renderType: Text.NativeRendering
    }
  
    // Declared before forgetBtn so forgetBtn sits on top and receives clicks first
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: row.activate()
    }
  
    // Forget button — declared after main MouseArea so it has higher Z and wins clicks
    Item {
      id: forgetBtn
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
      width: forgetLabel.implicitWidth + 10; height: 18
      visible: (row.saved || row.connected) && rowHover.hovered
  
      Rectangle {
        anchors.fill: parent; radius: height / 2
        color: forgetMa.containsMouse ? "#7a1f1f" : "#3a0f0f"
        border.width: 1
        border.color: forgetMa.containsMouse ? "#e04040" : "#c03030"
      }
  
      Text {
        id: forgetLabel
        anchors.centerIn: parent
        text: "Forget"
        font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
        color: forgetMa.containsMouse ? "#ff6060" : "#e04040"
        renderType: Text.NativeRendering
      }
  
      MouseArea {
        id: forgetMa
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onClicked: (e) => { e.accepted = true; row.forget() }
      }
    }
  }
  component WifiPasswordForm: Item {
    id: root
  
    readonly property var network: WifiState.pendingNetwork
  
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    onVisibleChanged: {
      if (visible) Qt.callLater(function() { passInput.forceActiveFocus() })
      else { passInput.text = ""; passInput.showPass = false }
    }
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // ── Header: back + SSID ───────────────────────────────────────────────────
      Item {
        width: parent.width; height: 42
  
        Text {
          id: backBtn
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "‹"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 6
          color: Theme.foreground
          opacity: backHov.hovered ? 1.0 : 0.5
          renderType: Text.NativeRendering
          HoverHandler { id: backHov }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WifiState.cancelPassword()
          }
        }
  
        Text {
          anchors {
            left: backBtn.right; leftMargin: 6
            right: parent.right; rightMargin: 14
            verticalCenter: parent.verticalCenter
          }
          text: root.network ? root.network.ssid : ""
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.9
          elide: Text.ElideRight
          renderType: Text.NativeRendering
        }
      }
  
      // ── "PASSWORD" label ──────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 26
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "PASSWORD"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      // ── Password input ────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 42
  
        Rectangle {
          anchors { fill: parent; leftMargin: 10; rightMargin: 10; bottomMargin: 6 }
          radius: 8
          color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.08)
          border.width: 1
          border.color: passInput.activeFocus
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
            : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
  
          TextInput {
            id: passInput
            anchors {
              left: parent.left; right: eyeBtn.left
              leftMargin: 12; rightMargin: 6
              verticalCenter: parent.verticalCenter
            }
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground
            echoMode: passInput.showPass ? TextInput.Normal : TextInput.Password
            selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
            selectByMouse: true
            clip: true
            renderType: Text.NativeRendering
  
            property bool showPass: false
  
            Keys.onReturnPressed: doConnect()
            Keys.onEnterPressed:  doConnect()
            Keys.onEscapePressed: WifiState.cancelPassword()
  
            MouseArea {
              anchors.fill: parent
              onClicked: parent.forceActiveFocus()
            }
          }
  
          // Show / hide toggle
          Text {
            id: eyeBtn
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: passInput.showPass ? "Hide" : "Show"
            font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
            color: Theme.foreground
            opacity: eyeHov.hovered ? 0.9 : 0.35
            renderType: Text.NativeRendering
            HoverHandler { id: eyeHov }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: passInput.showPass = !passInput.showPass
            }
          }
        }
      }
  
      // ── Buttons ───────────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 46
  
        // Cancel
        Item {
          id: cancelBtn
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          width: cancelLabel.implicitWidth + 20; height: 28
  
          Rectangle {
            anchors.fill: parent; radius: height / 2
            color: cancelMa.containsMouse
              ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
              : "transparent"
            border.width: 1
            border.color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.2)
          }
          Text {
            id: cancelLabel
            anchors.centerIn: parent
            text: "Cancel"
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground
            opacity: cancelMa.containsMouse ? 1.0 : 0.6
            renderType: Text.NativeRendering
          }
          MouseArea {
            id: cancelMa
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: WifiState.cancelPassword()
          }
        }
  
        // Connect
        Item {
          id: connectBtn
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          width: connectLabel.implicitWidth + 20; height: 28
          enabled: passInput.text.length >= 8
  
          Rectangle {
            anchors.fill: parent; radius: height / 2
            color: connectBtn.enabled
              ? (connectMa.containsMouse
                  ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 1.0)
                  : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85))
              : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
            Behavior on color { ColorAnimation { duration: 120 } }
          }
          Text {
            id: connectLabel
            anchors.centerIn: parent
            text: "Connect"
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: connectBtn.enabled ? Theme.background : Theme.foreground
            opacity: connectBtn.enabled ? 1.0 : 0.3
            renderType: Text.NativeRendering
          }
          MouseArea {
            id: connectMa
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            enabled: connectBtn.enabled
            onClicked: doConnect()
          }
        }
      }
  
      Item { width: parent.width; height: 4 }
    }
  
    function doConnect() {
      if (passInput.text.length < 8 || !root.network) return
      WifiState.connectWithPassword(root.network.ssid, passInput.text)
    }
  }
  component WifiPopup: Item {
    id: root
  
    implicitWidth: 280
    implicitHeight: WifiState.pendingNetwork !== null ? passForm.implicitHeight : networkCol.implicitHeight
    Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
  
    // ── Password form (shown when a network is pending password) ──────────────
    WifiPasswordForm {
      id: passForm
      anchors { left: parent.left; right: parent.right; top: parent.top }
      visible: WifiState.pendingNetwork !== null
    }
  
    // ── Network list ──────────────────────────────────────────────────────────
    Column {
      id: networkCol
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
      visible: WifiState.pendingNetwork === null
  
      // ── Header: title + scan + toggle + settings ────────────────────────────
      Item {
        width: parent.width; height: 42
  
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "WIFI"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
  
        Text {
          id: settingsBtn
          anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
          text: Glyphs.settings
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground
          opacity: settingsHov.hovered ? 0.9 : 0.35
          renderType: Text.NativeRendering
          HoverHandler { id: settingsHov }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WifiState.openSettings()
          }
        }
  
        Item {
          id: toggle
          anchors { right: settingsBtn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
          width: 36; height: 20
  
          Rectangle {
            anchors.fill: parent; radius: height / 2
            color: WifiState.wifiEnabled
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.9)
              : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.2)
            Behavior on color { ColorAnimation { duration: 150 } }
          }
  
          Rectangle {
            width: 16; height: 16; radius: 8; color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: WifiState.wifiEnabled ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
          }
  
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WifiState.toggleWifi()
          }
        }
      }
  
      // ── Off state ─────────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 32
        visible: !WifiState.wifiEnabled
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "Wi-Fi is off"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.4
          renderType: Text.NativeRendering
        }
      }
  
      // ── Connected ─────────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 26
        visible: WifiState.wifiEnabled && WifiState.connected.length > 0
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "CONNECTED"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      Repeater {
        model: WifiState.wifiEnabled ? WifiState.connected : []
        delegate: WifiNetworkRow {
          required property var modelData
          width: networkCol.width
          ssid: modelData.ssid; signal: modelData.signal
          secured: modelData.secured; connected: true; saved: modelData.saved
          onActivate: WifiState.disconnect()
          onForget: WifiState.forget(modelData.ssid)
        }
      }
  
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: WifiState.wifiEnabled && WifiState.connected.length > 0
                 && (WifiState.saved.length > 0 || WifiState.nearby.length > 0)
      }
  
      // ── Saved ─────────────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 26
        visible: WifiState.wifiEnabled && WifiState.saved.length > 0
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "SAVED"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      Repeater {
        model: WifiState.wifiEnabled ? WifiState.saved : []
        delegate: WifiNetworkRow {
          required property var modelData
          width: networkCol.width
          ssid: modelData.ssid; signal: modelData.signal
          secured: modelData.secured; connected: false; saved: true
          onActivate: WifiState.connect(modelData.ssid)
          onForget: WifiState.forget(modelData.ssid)
        }
      }
  
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: WifiState.wifiEnabled && WifiState.saved.length > 0 && WifiState.nearby.length > 0
      }
  
      // ── Nearby ────────────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 26
        visible: WifiState.wifiEnabled && WifiState.nearby.length > 0
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "NEARBY"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      Repeater {
        model: WifiState.wifiEnabled ? WifiState.nearby.slice(0, 8) : []
        delegate: WifiNetworkRow {
          required property var modelData
          width: networkCol.width
          ssid: modelData.ssid; signal: modelData.signal
          secured: modelData.secured; connected: false; saved: false
          onActivate: {
            if (modelData.secured)
              WifiState.promptPassword(modelData)
            else
              WifiState.connect(modelData.ssid)
          }
        }
      }
  
      // ── No networks ───────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 36
        visible: WifiState.wifiEnabled && WifiState.networks.length === 0
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "No networks found — press Scan"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.4
          renderType: Text.NativeRendering
        }
      }
  
      Item { width: parent.width; height: 8 }
    }
  }
  component BtDeviceRow: Item {
    id: row
  
    property string deviceName: ""
    property string deviceMac: ""
    property bool isConnected: false
    property bool removable: false
    signal activate()
    signal remove()
  
    height: 30
  
    MouseArea {
      id: ma
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: (e) => {
        if (row.removable && removeBtn.visible && e.x >= removeBtn.x) return
        row.activate()
      }
    }
  
    Rectangle {
      anchors.fill: parent
      color: row.isConnected
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
        : ma.containsMouse
          ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.18)
          : "transparent"
    }
  
    Text {
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      text: "▶"
      font.family: Theme.font
      font.pixelSize: Theme.fontSize - 2
      color: Theme.accent
      visible: row.isConnected
      renderType: Text.NativeRendering
    }
  
    Text {
      anchors {
        left: parent.left; leftMargin: 32
        right: removeBtn.visible ? removeBtn.left : parent.right
        rightMargin: removeBtn.visible ? 6 : 14
        verticalCenter: parent.verticalCenter
      }
      text: row.deviceName
      font.family: Theme.font
      font.pixelSize: Theme.fontSize
      color: row.isConnected ? Theme.accent : Theme.foreground
      opacity: row.isConnected ? 1.0 : (ma.containsMouse ? 1.0 : 0.7)
      elide: Text.ElideRight
      renderType: Text.NativeRendering
    }
  
    // Remove button
    Item {
      id: removeBtn
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
      width: removeLabel.implicitWidth + 10
      height: 18
      visible: row.removable && ma.containsMouse
  
      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: rmMa.containsMouse ? "#7a1f1f" : "#3a0f0f"
        border.width: 1
        border.color: rmMa.containsMouse ? "#e04040" : "#c03030"
      }
  
      Text {
        id: removeLabel
        anchors.centerIn: parent
        text: "Remove"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
        color: rmMa.containsMouse ? "#ff6060" : "#e04040"
        opacity: 1.0
        renderType: Text.NativeRendering
      }
  
      MouseArea {
        id: rmMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.remove()
      }
    }
  }
  component BtSection: Item {
    id: root
  
    property string label: ""
    property var devices: []
    property bool isConnectedSection: false
    property bool showRemove: false
    signal activate(string mac)
  
    implicitHeight: sectionCol.implicitHeight
  
    Column {
      id: sectionCol
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      Item {
        width: parent.width; height: 26
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: root.label
          font.family: Theme.font
          font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground
          opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      Repeater {
        model: root.devices
        delegate: BtDeviceRow {
          required property var modelData
          width: root.width
          deviceName: modelData.name
          deviceMac: modelData.mac
          isConnected: root.isConnectedSection
          removable: root.showRemove
          onActivate: root.activate(deviceMac)
          onRemove: BluetoothState.remove(deviceMac)
        }
      }
    }
  }
  component BluetoothPopup: Item {
    id: root
  
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // ── Header: title + toggle + settings ────────────────────────────────
      Item {
        width: parent.width
        height: 42
  
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "BLUETOOTH"
          font.family: Theme.font
          font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground
          opacity: 0.7
          renderType: Text.NativeRendering
        }
  
        // Settings button
        Text {
          id: settingsBtn
          anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
          text: Glyphs.settings
          font.family: Theme.font
          font.pixelSize: Theme.fontSize
          color: Theme.foreground
          opacity: settingsHov.containsMouse ? 0.9 : 0.35
          renderType: Text.NativeRendering
          HoverHandler { id: settingsHov }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              BluetoothState.hide()
              Quickshell.execDetached(["omarchy-launch-bluetooth"])
            }
          }
        }
  
        // Scan button
        Item {
          id: scanBtn
          anchors { right: powerLabel.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
          width: scanLabel.implicitWidth + 16
          height: 22
          visible: BluetoothState.powered
  
          Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: BluetoothState.scanning
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
              : scanMa.containsMouse
                ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
                : "transparent"
            border.width: 1
            border.color: BluetoothState.scanning
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
              : scanMa.containsMouse
                ? Qt.rgba(1, 1, 1, 0.5)
                : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.25)
          }
  
          MouseArea {
            id: scanMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: BluetoothState.scanning ? BluetoothState.stopScan() : BluetoothState.startScan()
          }
  
          Text {
            id: scanLabel
            anchors.centerIn: parent
            text: BluetoothState.scanning ? "Scanning…" : "Scan"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            color: BluetoothState.scanning
              ? Theme.accent
              : scanMa.containsMouse ? "white" : Theme.foreground
            opacity: BluetoothState.scanning ? 1.0 : (scanMa.containsMouse ? 1.0 : 0.7)
            renderType: Text.NativeRendering
  
            SequentialAnimation on opacity {
              running: BluetoothState.scanning
              loops: Animation.Infinite
              NumberAnimation { to: 0.4; duration: 700; easing.type: Easing.InOutSine }
              NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            }
          }
        }
  
        // Power state label
        Text {
          id: powerLabel
          anchors { right: toggle.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
          text: BluetoothState.powered ? "On" : "Off"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: BluetoothState.powered ? Theme.accent : Theme.foreground
          opacity: BluetoothState.powered ? 0.8 : 0.35
          renderType: Text.NativeRendering
        }
  
        // Toggle slider
        Item {
          id: toggle
          anchors { right: settingsBtn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
          width: 36; height: 20
  
          Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: BluetoothState.powered
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.9)
              : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.2)
            Behavior on color { ColorAnimation { duration: 150 } }
          }
  
          Rectangle {
            id: knob
            width: 16; height: 16
            radius: 8
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: BluetoothState.powered ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
          }
  
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: BluetoothState.togglePower()
          }
        }
      }
  
      // ── Connected ──────────────────────────────────────────────────────────
      BtSection {
        width: parent.width
        label: "CONNECTED"
        devices: BluetoothState.connected
        visible: BluetoothState.powered && BluetoothState.connected.length > 0
        onActivate: (mac) => BluetoothState.disconnect(mac)
        isConnectedSection: true
        showRemove: true
      }
  
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: BluetoothState.powered
                 && BluetoothState.connected.length > 0
                 && (BluetoothState.known.length > 0 || BluetoothState.nearby.length > 0)
      }
  
      // ── Known (paired, not connected) ─────────────────────────────────────
      BtSection {
        width: parent.width
        label: "KNOWN DEVICES"
        devices: BluetoothState.known
        visible: BluetoothState.known.length > 0
        onActivate: (mac) => { if (BluetoothState.powered) BluetoothState.connect(mac) }
        isConnectedSection: false
        showRemove: true
      }
  
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: BluetoothState.known.length > 0
                 && BluetoothState.powered
                 && BluetoothState.nearby.length > 0
      }
  
      // ── Nearby (scanning results) ─────────────────────────────────────────
      BtSection {
        width: parent.width
        label: BluetoothState.scanning ? "NEARBY  ·  scanning…" : "NEARBY"
        devices: BluetoothState.nearby
        visible: BluetoothState.powered && (BluetoothState.nearby.length > 0 || BluetoothState.scanning)
        onActivate: (mac) => BluetoothState.connect(mac)
        isConnectedSection: false
      }
  
      // Scanning but no nearby devices yet
      Item {
        width: parent.width; height: 32
        visible: BluetoothState.powered
                 && BluetoothState.scanning
                 && BluetoothState.nearby.length === 0
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "Looking for devices…"
          font.family: Theme.font
          font.pixelSize: Theme.fontSize
          color: Theme.foreground
          opacity: 0.4
          renderType: Text.NativeRendering
        }
      }
  
      // Not scanning and no nearby
      Item {
        width: parent.width; height: 32
        visible: BluetoothState.powered
                 && !BluetoothState.scanning
                 && BluetoothState.nearby.length > 0 === false
                 && BluetoothState.known.length === 0
                 && BluetoothState.connected.length === 0
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "No known devices"
          font.family: Theme.font
          font.pixelSize: Theme.fontSize
          color: Theme.foreground
          opacity: 0.4
          renderType: Text.NativeRendering
        }
      }
  
  
      Item { width: parent.width; height: 8 }
    }
  }
  component AudioSection: Item {
    id: root
  
    property string label: ""
    property var devices: []
    property bool collapsed: true
    signal activate(string name)
  
    visible: devices.length > 0
    height: headerItem.height + contentArea.height
    implicitHeight: height
  
    // ── Header (always visible, clickable to toggle) ─────────────────────
    Item {
      id: headerItem
      width: parent.width
      height: 26
  
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.collapsed = !root.collapsed
      }
  
      Text {
        id: chevron
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: "›"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 3
        color: Theme.foreground
        opacity: headerHov.containsMouse ? 0.7 : 0.4
        renderType: Text.NativeRendering
        rotation: root.collapsed ? 0 : 90
        transformOrigin: Item.Center
        Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.InOutQuad } }
      }
      HoverHandler { id: headerHov }
  
      Text {
        anchors { left: chevron.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
        text: root.label
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground
        opacity: 0.7
        renderType: Text.NativeRendering
      }
    }
  
    // ── Content (animated collapse) ───────────────────────────────────────
    Item {
      id: contentArea
      anchors { top: headerItem.bottom; left: parent.left; right: parent.right }
      height: root.collapsed ? 0 : contentCol.implicitHeight
      clip: true
      Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.InOutQuad } }
  
      Column {
        id: contentCol
        width: parent.width
        spacing: 0
  
        Repeater {
          model: root.devices
  
          delegate: Item {
            id: row
            required property var modelData
            width: root.width
            height: 30
  
            readonly property bool isActive: modelData.active === true
  
            MouseArea {
              id: ma
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activate(row.modelData.name)
            }
  
            Rectangle {
              anchors.fill: parent
              color: row.isActive
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                : ma.containsMouse
                  ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.18)
                  : "transparent"
            }
  
            Text {
              anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
              text: "▶"
              font.family: Theme.font
              font.pixelSize: Theme.fontSize - 2
              color: Theme.accent
              visible: row.isActive
              renderType: Text.NativeRendering
            }
  
            Text {
              anchors {
                left: parent.left; leftMargin: 32
                right: parent.right; rightMargin: 14
                verticalCenter: parent.verticalCenter
              }
              text: row.modelData.desc || row.modelData.name
              font.family: Theme.font
              font.pixelSize: Theme.fontSize
              color: row.isActive ? Theme.accent : Theme.foreground
              opacity: row.isActive ? 1.0 : (ma.containsMouse ? 1.0 : 0.7)
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }
          }
        }
  
        Item { width: parent.width; height: 8 }
      }
    }
  }
  component AppMixer: Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    property var streams: []
    property real masterVol: 1.0
    property bool masterMuted: false
    property bool dragging: false
  
    function refresh() { if (!dragging && !streamsProc.running) streamsProc.running = true }
  
    Timer {
      interval: 2000
      running: AudioState.visible
      repeat: true
      triggeredOnStart: true
      onTriggered: root.refresh()
    }
  
    Process {
      id: streamsProc
      command: ["omarchy-audio-streams"]
      stdout: StdioCollector { id: streamsBuf }
      onExited: (code) => {
        if (code !== 0) return
        try {
          // StdioCollector accumulates across runs — always use the last non-empty line
          var lines = streamsBuf.text.split('\n').filter(function(l) { return l.trim().length > 0 })
          var last = lines.length > 0 ? lines[lines.length - 1] : ""
          var d = JSON.parse(last)
          // Sanitize any overdriven sink-inputs left by previous broken code
          var streams = d.streams || []
          streams.forEach(function(s) {
            if (s.device) return  // device-volume entries are never overdriven
            if (s.vol > 100) {
              s.vol = 100
              var ids = s.indices || (s.index !== undefined ? [s.index] : [])
              ids.forEach(function(i) {
                Quickshell.execDetached(["bash", "-c",
                  "pactl set-sink-input-volume " + i + " 100%"])
              })
            }
          })
          root.streams     = streams
          root.masterVol   = (d.master ? d.master.vol : 100) / 100.0
          root.masterMuted = d.master ? d.master.muted : false
        } catch(e) {}
      }
    }
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // ── Master volume ─────────────────────────────────────────────────────
      Item {
        width: col.width
        height: 38
  
        Row {
          anchors {
            left: parent.left; right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 14; rightMargin: 14
          }
          spacing: 0
  
          Text {
            id: masterLabel
            width: 86
            text: "Master"
            elide: Text.ElideRight
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.foreground
            opacity: root.masterMuted ? 0.25 : 0.9
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }
  
          Item {
            id: masterSliderArea
            width: parent.width - masterLabel.width - masterVolLabel.width - masterMuteBtn.width - 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.masterMuted ? 0.35 : 1.0
  
            Rectangle {
              id: masterTrack
              anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
              height: 3; radius: 2
              color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
  
              Rectangle {
                width: parent.width * Math.min(root.masterVol, 1.0)
                height: parent.height; radius: parent.radius
                color: Theme.accent; opacity: 0.85
              }
            }
  
            Rectangle {
              x: masterTrack.width * Math.min(root.masterVol, 1.0) - width / 2
              anchors.verticalCenter: masterTrack.verticalCenter
              width: 10; height: 10; radius: 5
              color: Theme.accent
              visible: masterMa.containsMouse || masterMa.pressed
            }
  
            Timer {
              id: masterDebounce
              interval: 40
              onTriggered: Quickshell.execDetached(["bash", "-c",
                "pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(root.masterVol * 100) + "%"])
            }
  
            MouseArea {
              id: masterMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              function applyVol(mouseX) {
                root.masterVol = Math.max(0.0, Math.min(1.0, mouseX / masterTrack.width))
                masterDebounce.restart()
              }
              onPressed:         { root.dragging = true }
              onReleased:        { root.dragging = false }
              onClicked:         (mouse) => applyVol(mouse.x)
              onPositionChanged: (mouse) => { if (pressed) applyVol(mouse.x) }
            }
          }
  
          Item { width: 8; height: 1 }
  
          Text {
            id: masterVolLabel
            width: 34
            text: Math.round(root.masterVol * 100) + "%"
            horizontalAlignment: Text.AlignRight
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground
            opacity: root.masterMuted ? 0.25 : 0.5
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }
  
          Item { width: 8; height: 1 }
  
          Text {
            id: masterMuteBtn
            text: root.masterMuted ? Glyphs.paMutedX : Glyphs.paDefault[1]
            font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
            color: root.masterMuted ? Theme.activeRed : Theme.foreground
            opacity: root.masterMuted ? 0.9 : (masterMuteHov.containsMouse ? 0.8 : 0.35)
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
            HoverHandler { id: masterMuteHov }
            MouseArea {
              anchors.fill: parent; anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.masterMuted = !root.masterMuted
                Quickshell.execDetached(["bash", "-c",
                  "pactl set-sink-mute @DEFAULT_SINK@ toggle"])
              }
            }
          }
        }
      }
  
      // Separator between master and apps
      Rectangle {
        width: col.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.08)
      }
  
      Repeater {
        model: root.streams
  
        delegate: Item {
          required property var modelData
  
          // independent per-app vol (0–100%), capped at 100% — no overdriving
          property real localVol: Math.min(modelData.vol / 100.0, 1.0)
          property bool localMuted: modelData.muted
  
          width: col.width
          height: 36
  
          Row {
            anchors {
              left: parent.left; right: parent.right
              verticalCenter: parent.verticalCenter
              leftMargin: 14; rightMargin: 14
            }
            spacing: 0
  
            Text {
              id: nameLabel
              width: 86
              text: modelData.name
              elide: Text.ElideRight
              font.family: Theme.font
              font.pixelSize: Theme.fontSize
              color: Theme.foreground
              opacity: localMuted ? 0.25 : 0.75
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
            }
  
            Item {
              id: sliderArea
              width: parent.width - nameLabel.width - volLabel.width - muteBtn.width - 20
              height: 20
              anchors.verticalCenter: parent.verticalCenter
              opacity: localMuted ? 0.35 : 1.0
  
              Rectangle {
                id: trackBg
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 3; radius: 2
                color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
  
                Rectangle {
                  width: parent.width * localVol
                  height: parent.height; radius: parent.radius
                  color: Theme.accent; opacity: 0.85
                }
              }
  
              Rectangle {
                x: trackBg.width * Math.min(localVol, 1.0) - width / 2
                anchors.verticalCenter: trackBg.verticalCenter
                width: 10; height: 10; radius: 5
                color: Theme.accent
                visible: sliderMa.containsMouse || sliderMa.pressed
              }
  
              Timer {
                id: appDebounce
                interval: 40
                onTriggered: {
                  if (modelData.device) {
                    Quickshell.execDetached(["bash", "-c",
                      "pactl set-sink-volume " + modelData.device + " " + Math.round(localVol * 100) + "%"])
                    return
                  }
                  var ids = modelData.indices || (modelData.index !== undefined ? [modelData.index] : [])
                  ids.forEach(function(i) {
                    Quickshell.execDetached(["bash", "-c",
                      "pactl set-sink-input-volume " + i + " " + Math.round(localVol * 100) + "%"])
                  })
                }
              }
  
              MouseArea {
                id: sliderMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                function applyVol(mouseX) {
                  localVol = Math.max(0.0, Math.min(1.0, mouseX / trackBg.width))
                  appDebounce.restart()
                }
                onPressed:         { root.dragging = true }
                onReleased:        { root.dragging = false }
                onClicked:         (mouse) => applyVol(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) applyVol(mouse.x) }
              }
            }
  
            Item { width: 8; height: 1 }
  
            Text {
              id: volLabel
              width: 34
              text: Math.round(localVol * 100) + "%"
              horizontalAlignment: Text.AlignRight
              font.family: Theme.font; font.pixelSize: Theme.fontSize
              color: Theme.foreground
              opacity: localMuted ? 0.25 : 0.5
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
            }
  
            Item { width: 8; height: 1 }
  
            Text {
              id: muteBtn
              text: localMuted ? Glyphs.paMutedX : Glyphs.paDefault[1]
              font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
              color: localMuted ? Theme.activeRed : Theme.foreground
              opacity: localMuted ? 0.9 : (muteHov.containsMouse ? 0.8 : 0.35)
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
              HoverHandler { id: muteHov }
              MouseArea {
                anchors.fill: parent; anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  localMuted = !localMuted
                  if (modelData.device) {
                    Quickshell.execDetached(["bash", "-c",
                      "pactl set-sink-mute " + modelData.device + " toggle"])
                    return
                  }
                  var ids = modelData.indices || (modelData.index !== undefined ? [modelData.index] : [])
                  ids.forEach(function(i) {
                    Quickshell.execDetached(["bash", "-c",
                      "pactl set-sink-input-mute " + i + " toggle"])
                  })
                }
              }
            }
          }
        }
      }
  
      // Empty state
      Item {
        width: parent.width; height: 30
        visible: root.streams.length === 0
        Text {
          anchors { left: parent.left; leftMargin: 32; verticalCenter: parent.verticalCenter }
          text: "No active apps"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.35
          renderType: Text.NativeRendering
        }
      }
  
      Item { width: parent.width; height: 8 }
    }
  }
  component AudioPopup: Item {
    id: root
  
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // ── Header row (title + settings button) ─────────────────────────────
      Item {
        width: parent.width
        height: 30
  
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "Mixer"
          font.family: Theme.font
          font.pixelSize: Theme.fontSize + 2
          font.bold: true
          color: Theme.foreground
          opacity: 0.85
          renderType: Text.NativeRendering
        }
  
        Text {
          anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
          text: Glyphs.settings
          font.family: Theme.font
          font.pixelSize: Theme.fontSize
          color: Theme.foreground
          opacity: settingsHov.containsMouse ? 0.9 : 0.35
          renderType: Text.NativeRendering
          HoverHandler { id: settingsHov }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              AudioState.hide()
              Quickshell.execDetached(["omarchy-launch-audio"])
            }
          }
        }
      }
  
      // ── App Mixer ────────────────────────────────────────────────────────
      AppMixer {
        width: parent.width
      }
  
      // Separator
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: AudioState.sinks.length > 0 || AudioState.sources.length > 0
      }
  
      // ── Outputs ──────────────────────────────────────────────────────────
      AudioSection {
        width: parent.width
        label: "OUTPUTS"
        devices: AudioState.sinks
        onActivate: (name) => AudioState.setDefaultSink(name)
      }
  
      // Separator
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: AudioState.sinks.length > 0 && AudioState.sources.length > 0
      }
  
      // ── Inputs ───────────────────────────────────────────────────────────
      AudioSection {
        width: parent.width
        label: "INPUTS"
        devices: AudioState.sources
        onActivate: (name) => AudioState.setDefaultSource(name)
      }
    }
  }
  component NotifCenter: Item {
    id: root
    implicitWidth: 380
    implicitHeight: headerRow.implicitHeight
      + (hasNotifs
          ? clearBtn.implicitHeight + 4 + Math.min(listCol.implicitHeight, 220) + 8
          : emptyText.implicitHeight + 8)
  
    readonly property bool hasNotifs: NotifState.notifications.length > 0
  
    // ── Header ──────────────────────────────────────────────────────────────
    Item {
      id: headerRow
      width: parent.width
      implicitHeight: 18
  
      // "Notifications" label
      Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: "Notifications"
        font.family: Theme.font; font.pixelSize: 11
        color: Theme.foreground; opacity: 0.4
        renderType: Text.NativeRendering
      }
  
      // DND toggle slider (top-right)
      Item {
        id: dndToggle
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 28; height: 16
  
        Rectangle {
          anchors.fill: parent
          radius: height / 2
          color: NotifState.muted
            ? Qt.rgba(Theme.activeRed.r, Theme.activeRed.g, Theme.activeRed.b, 0.85)
            : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85)
          Behavior on color { ColorAnimation { duration: 150 } }
        }
  
        Rectangle {
          width: 12; height: 12
          radius: 6
          color: "white"
          anchors.verticalCenter: parent.verticalCenter
          x: NotifState.muted ? 2 : parent.width - width - 2
          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        }
  
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: NotifState.toggleMute()
        }
      }
  
      // Bell icon — left of the slider
      Text {
        anchors { right: dndToggle.left; rightMargin: 6; verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
        text: NotifState.muted ? Glyphs.notifBellOff : Glyphs.notifBell
        font.family: Theme.font; font.pixelSize: 11
        color: NotifState.muted ? Theme.activeRed : Theme.foreground
        opacity: NotifState.muted ? 1.0 : 0.4
        renderType: Text.NativeRendering
      }
    }
  
    // "Clear all" — on its own line below the bell icon + DND slider.
    Text {
      id: clearBtn
      visible: root.hasNotifs
      anchors { top: headerRow.bottom; topMargin: 4; right: parent.right }
      text: "Clear all"
      font.family: Theme.font; font.pixelSize: 11
      color: Theme.foreground; opacity: 0.4
      renderType: Text.NativeRendering
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: NotifState.clearAll()
      }
    }
  
    // ── Empty state ─────────────────────────────────────────────────────────
    Text {
      id: emptyText
      visible: !root.hasNotifs
      anchors { top: headerRow.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
      text: "No notifications"
      font.family: Theme.font; font.pixelSize: 11
      color: Theme.foreground; opacity: 0.3
      renderType: Text.NativeRendering
    }
  
    // ── List ─────────────────────────────────────────────────────────────────
    Item {
      visible: root.hasNotifs
      anchors { top: clearBtn.bottom; topMargin: 8; left: parent.left; right: parent.right }
      height: Math.min(listCol.implicitHeight, 220)
      clip: true
  
      Column {
        id: listCol
        width: parent.width
        spacing: 6
  
        Repeater {
          // ScriptModel diffs the array and emits granular row inserts/removes
          // instead of a full reset, so the Repeater never calls regenerate()
          // (which segfaulted Qt's QML incubator when the whole array was
          // reassigned on each incoming notification).
          model: ScriptModel { values: NotifState.notifications }
  
          delegate: Rectangle {
            required property var modelData
            required property int index
            // modelData can briefly turn null if its Notification QObject is
            // destroyed; collapse and guard everything against that.
            visible: modelData != null
            width: listCol.width
            implicitHeight: modelData != null ? itemContent.implicitHeight + 16 : 0
            radius: 8
            color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.05)
  
            Column {
              id: itemContent
              anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; rightMargin: 28 }
              spacing: 2
  
              Text {
                text: NotifState.sourceLabel(modelData)
                font.family: Theme.font; font.pixelSize: 9
                color: Theme.foreground; opacity: 0.4
                renderType: Text.NativeRendering
              }
              Text {
                width: parent.width
                wrapMode: Text.Wrap
                text: NotifState.title(modelData)
                font.family: Theme.font; font.pixelSize: 12; font.bold: true
                color: Theme.foreground
                renderType: Text.NativeRendering
              }
              Text {
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text.length > 0
                text: NotifState.subtitle(modelData)
                font.family: Theme.font; font.pixelSize: 11
                color: Theme.foreground; opacity: 0.6
                renderType: Text.NativeRendering
              }
            }
  
            MouseArea {
              anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 28 }
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!modelData) return
                if ((modelData.summary || "").indexOf("Screenshot") >= 0) {
                  Quickshell.execDetached(["bash", "-c",
                    "f=$(ls -t ~/Pictures/screenshot-*.png 2>/dev/null | head -1); [ -n \"$f\" ] && satty --filename \"$f\" --output-filename \"$f\" --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy"])
                }
                var acts = modelData.actions || []
                for (var i = 0; i < acts.length; i++) {
                  if (acts[i].identifier === "default") { try { acts[i].invoke() } catch (e) {} break }
                }
                NotifState.dismiss(modelData)
              }
            }
  
            Text {
              anchors { right: parent.right; bottom: itemContent.bottom; rightMargin: 8; bottomMargin: 0 }
              text: modelData ? (modelData.receivedAt || "") : ""
              font.family: Theme.font; font.pixelSize: 9
              color: Theme.foreground; opacity: 0.85
              renderType: Text.NativeRendering
            }
  
            Text {
              anchors { right: parent.right; top: parent.top; margins: 8 }
              text: "✕"
              font.pixelSize: 11
              color: Theme.foreground; opacity: 0.4
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotifState.dismiss(modelData)
              }
            }
          }
        }
      }
    }
  }
  component CalendarPopup: Item {
    id: root
    property var now: new Date()
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
  
    readonly property var monthNames: [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ]
    readonly property var dayNames: ["Mo","Tu","We","Th","Fr","Sa","Su"]
  
    function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    // Monday-first: 0=Mon … 6=Sun
    function firstWeekday(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7 }
  
    function weatherIcon(code) {
      if (code === 113) return "☀️"
      if (code === 116) return "⛅"
      if (code === 119 || code === 122) return "☁️"
      if (code === 143 || code === 248 || code === 260) return "🌫️"
      if ([200,386,389,392,395].indexOf(code) >= 0) return "⛈️"
      if ([179,182,185,281,284,311,314,317,320,323,326,329,332,335,338,350,362,365,368,371,374,377].indexOf(code) >= 0) return "❄️"
      if ([176,263,266,293,296,299,302,305,308,353,356,359].indexOf(code) >= 0) return "🌧️"
      return "🌡️"
    }
  
    // Only tick the seconds clock while the calendar is actually shown.
    Timer { interval: 1000; running: CalendarState.visible; repeat: true; onTriggered: root.now = new Date() }
  
    // Reset view to current month when popup opens
    Connections {
      target: CalendarState
      function onVisibleChanged() {
        if (CalendarState.visible) {
          root.viewYear  = root.now.getFullYear()
          root.viewMonth = root.now.getMonth()
        }
      }
    }
  
    implicitHeight: mainColumn.implicitHeight
    implicitWidth: mainColumn.implicitWidth
  
    Column {
      id: mainColumn
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      spacing: 10
  
      // ── Time ──────────────────────────────────────────────────────────────
      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
  
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(root.now, "HH:mm:ss")
          font.family: Theme.font
          font.pixelSize: 28
          color: Theme.foreground
          renderType: Text.NativeRendering
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(root.now, "dddd, d MMMM yyyy")
          font.family: Theme.font
          font.pixelSize: 11
          color: Theme.foreground
          opacity: 0.6
          renderType: Text.NativeRendering
        }
      }
  
      // Separator
      Rectangle {
        width: mainRow.implicitWidth; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
      }
  
      // ── Calendar + Weather side by side ───────────────────────────────────
      Row {
        id: mainRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0
  
        // ── Calendar ────────────────────────────────────────────────────────
        Column {
          id: calColumn
          spacing: 6
  
          // Month nav
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
  
            Text {
              text: "‹"
              font.family: Theme.font
              font.pixelSize: 16
              color: Theme.foreground
              width: 28; height: 20
              horizontalAlignment: Text.AlignHCenter
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  CalendarState.show()
                  root.viewMonth--
                  if (root.viewMonth < 0) { root.viewMonth = 11; root.viewYear-- }
                }
              }
            }
  
            Text {
              text: root.monthNames[root.viewMonth] + "  " + root.viewYear
              font.family: Theme.font
              font.pixelSize: 12
              color: Theme.foreground
              width: 160; height: 20
              horizontalAlignment: Text.AlignHCenter
              renderType: Text.NativeRendering
            }
  
            Text {
              text: "›"
              font.family: Theme.font
              font.pixelSize: 16
              color: Theme.foreground
              width: 28; height: 20
              horizontalAlignment: Text.AlignHCenter
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  CalendarState.show()
                  root.viewMonth++
                  if (root.viewMonth > 11) { root.viewMonth = 0; root.viewYear++ }
                }
              }
            }
          }
  
          // Weekday headers
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Repeater {
              model: root.dayNames
              Text {
                width: 28; height: 16
                text: modelData
                font.family: Theme.font
                font.pixelSize: 9
                color: Theme.foreground
                opacity: 0.4
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
              }
            }
          }
  
          // Day cells
          Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 7
            rowSpacing: 2
            columnSpacing: 2
  
            Repeater {
              model: root.firstWeekday(root.viewYear, root.viewMonth)
                     + root.daysInMonth(root.viewYear, root.viewMonth)
  
              delegate: Item {
                width: 28; height: 24
  
                readonly property int offset: root.firstWeekday(root.viewYear, root.viewMonth)
                readonly property bool isDay: index >= offset
                readonly property int dayNum: index - offset + 1
                readonly property bool isToday: isDay
                  && dayNum === root.now.getDate()
                  && root.viewMonth === root.now.getMonth()
                  && root.viewYear === root.now.getFullYear()
  
                Rectangle {
                  anchors.centerIn: parent
                  width: 24; height: 24; radius: 12
                  color: Theme.accent
                  visible: parent.isToday
                }
  
                Text {
                  anchors.centerIn: parent
                  text: parent.isDay ? ("" + parent.dayNum) : ""
                  font.family: Theme.font
                  font.pixelSize: 11
                  color: parent.isToday ? Theme.background : Theme.foreground
                  opacity: parent.isToday ? 1.0 : 0.8
                  renderType: Text.NativeRendering
                }
              }
            }
          }
        }
  
        // ── Vertical divider ────────────────────────────────────────────────
        Item {
          visible: CalendarState.weather !== null
          width: 17
          implicitHeight: calColumn.implicitHeight
          Rectangle {
            anchors.centerIn: parent
            width: 1; height: parent.height
            color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
          }
        }
  
        // ── Weather ─────────────────────────────────────────────────────────
        Item {
          id: weatherItem
          visible: CalendarState.weather !== null
          implicitWidth: 170
          implicitHeight: calColumn.implicitHeight
  
          Column {
            id: weatherInner
            anchors.centerIn: parent
            width: 154  // weatherItem.implicitWidth - 16 padding
            spacing: 14
  
            // Today
            Column {
              width: parent.width
              spacing: 6
  
              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
  
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: CalendarState.weather ? root.weatherIcon(CalendarState.weather.current.code) : ""
                  font.pixelSize: 30
                  renderType: Text.NativeRendering
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: CalendarState.weather ? (CalendarState.weather.current.temp + "°C") : ""
                  font.family: Theme.font
                  font.pixelSize: 30
                  color: Theme.foreground
                  renderType: Text.NativeRendering
                }
              }
  
              Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: CalendarState.weather ? CalendarState.weather.current.desc : ""
                font.family: Theme.font
                font.pixelSize: 13
                color: Theme.foreground
                opacity: 0.7
                renderType: Text.NativeRendering
              }
  
              Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: CalendarState.weather
                  ? ("Feels " + CalendarState.weather.current.feelsLike + "°  ·  " + Glyphs.humidity + " "
                     + CalendarState.weather.current.humidity + " %")
                  : ""
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.foreground
                opacity: 0.5
                renderType: Text.NativeRendering
              }
            }
  
            // 3-day forecast
            Column {
              width: parent.width
              spacing: 8
  
              Repeater {
                model: CalendarState.weather ? CalendarState.weather.days : []
                delegate: Row {
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: 8
  
                  Text {
                    width: 36
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.dayName
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.foreground
                    opacity: 0.5
                    renderType: Text.NativeRendering
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weatherIcon(modelData.code)
                    font.pixelSize: 16
                  }
                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.max + "° / " + modelData.min + "°"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.foreground
                    opacity: 0.7
                    renderType: Text.NativeRendering
                  }
                }
              }
            }
          }
        }
      }
  
      // ── Notification center ───────────────────────────────────────────────
      Rectangle {
        width: mainRow.implicitWidth; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
      }
  
      NotifCenter {
        implicitWidth: mainRow.implicitWidth
      }
    }
  }
  component KbLayoutRow: Item {
    id: row
  
    property string code: ""
    property string name: ""
  
    readonly property bool isFav: {
      var codes = KbLayoutState.favoriteCodes
      return codes.indexOf(code) >= 0
    }
    readonly property bool isActive: {
      var cur = KbLayoutState.currentLayout.toLowerCase()
      var c = code.toLowerCase()
      return cur === c || (c === "us" && cur === "en") || (c === "es" && cur === "es")
    }
  
    height: 30
    width: parent ? parent.width : 280
  
    HoverHandler { id: rowHover }
  
    Rectangle {
      anchors.fill: parent
      color: row.isActive
        ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
        : rowHover.hovered
          ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
          : "transparent"
    }
  
    Text {
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      text: "▶"
      font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
      color: Theme.accent
      visible: row.isActive
      renderType: Text.NativeRendering
    }
  
    Text {
      anchors {
        left: parent.left; leftMargin: 32
        right: starBtn.left; rightMargin: 4
        verticalCenter: parent.verticalCenter
      }
      text: row.name
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: row.isActive ? Theme.accent : Theme.foreground
      opacity: row.isActive ? 1.0 : (ma.containsMouse ? 1.0 : 0.8)
      elide: Text.ElideRight
      renderType: Text.NativeRendering
    }
  
    Text {
      id: codeLabel
      anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
      text: row.code.toUpperCase()
      font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
      color: row.isFav ? Theme.accent : Theme.foreground
      opacity: row.isFav ? 0.7 : 0.35
      renderType: Text.NativeRendering
    }
  
    // Row click — declared before starBtn so starBtn sits on top
    MouseArea {
      id: ma
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: KbLayoutState.setLayout(row.code)
    }
  
    // Star button — uses rowHover (HoverHandler) to avoid hover-steal bug with ma
    Item {
      id: starBtn
      anchors { right: codeLabel.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
      width: 26; height: 26
      visible: row.isFav || rowHover.hovered
  
      Text {
        anchors.centerIn: parent
        text: row.isFav ? "★" : "☆"
        font.family: Theme.font; font.pixelSize: Theme.fontSize + 5
        color: row.isFav
          ? (starMa.containsMouse ? "#ffffff" : Theme.accent)
          : (starMa.containsMouse ? "#ffffff" : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.45))
        renderType: Text.NativeRendering
      }
  
      MouseArea {
        id: starMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (e) => {
          e.accepted = true
          KbLayoutState.toggleFavorite(row.code, row.name)
        }
      }
    }
  }
  component KbLayoutPopup: Item {
    id: root
  
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    property string searchText: searchInput.text
  
    readonly property var filteredLayouts: {
      var q = searchText.toLowerCase().trim()
      if (q === "") return KbLayoutState.allLayouts
      return KbLayoutState.allLayouts.filter(function(l) {
        return l.name.toLowerCase().indexOf(q) >= 0 || l.code.toLowerCase().indexOf(q) >= 0
      })
    }
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // ── Header ───────────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 42
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "KEYBOARD LAYOUT"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      // ── Search box ───────────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 36
  
        Rectangle {
          anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 0; bottomMargin: 6 }
          radius: 8
          color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.08)
          border.width: 1
          border.color: searchInput.activeFocus
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
            : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
  
          Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: "Search…"
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground; opacity: 0.3
            renderType: Text.NativeRendering
            visible: searchInput.text === ""
          }
  
          TextInput {
            id: searchInput
            anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground
            selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
            selectByMouse: true
            clip: true
            MouseArea {
              anchors.fill: parent
              onClicked: parent.forceActiveFocus()
            }
          }
        }
      }
  
  
      // ── Favorites section (only when not searching) ───────────────────────────
      Item {
        width: parent.width; height: 26
        visible: searchText === ""
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "FAVORITES"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      // Favorites with drag-to-reorder (live reorder, items shift during drag)
      Item {
        id: favDragContainer
        width: col.width
        height: KbLayoutState.favorites.length * 30
        visible: searchText === ""
  
        property string draggingCode: ""
        property int dragFromIndex: -1
        property int dragToIndex: -1
        property real dragY: 0
        property bool dragActive: false
  
        Repeater {
          model: KbLayoutState.favorites
  
          delegate: Item {
            id: favWrapper
            required property int index
            required property var modelData
            width: favDragContainer.width
            height: 30
  
            readonly property bool isBeingDragged: modelData.code === favDragContainer.draggingCode
  
            y: {
              var from = favDragContainer.dragFromIndex
              var to   = favDragContainer.dragToIndex
              if (from < 0) return index * 30
              if (isBeingDragged) return Math.max(0, Math.min((KbLayoutState.favorites.length - 1) * 30, favDragContainer.dragY))
              if (from < to && index > from && index <= to) return index * 30 - 30
              if (from > to && index >= to && index < from) return index * 30 + 30
              return index * 30
            }
  
            Behavior on y {
              enabled: favDragContainer.dragActive && !favWrapper.isBeingDragged
              NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
  
            opacity: isBeingDragged ? 0.5 : 1.0
            z: isBeingDragged ? 10 : 0
  
            Item {
              anchors { left: parent.left; verticalCenter: parent.verticalCenter }
              width: 22; height: parent.height
  
              Text {
                anchors.centerIn: parent
                text: "⠿"
                font.family: Theme.font; font.pixelSize: Theme.fontSize
                color: Theme.foreground
                opacity: gripMa.containsMouse ? 0.65 : 0.22
                renderType: Text.NativeRendering
              }
  
              MouseArea {
                id: gripMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeVerCursor
  
                property real dragOffsetY: 0
  
                onPressed: (mouse) => {
                  var p = favWrapper.mapToItem(favDragContainer, 0, 0)
                  var pressInContainer = mapToItem(favDragContainer, mouse.x, mouse.y)
                  dragOffsetY = pressInContainer.y - p.y
                  favDragContainer.dragY = p.y
                  favDragContainer.dragFromIndex = favWrapper.index
                  favDragContainer.dragToIndex = favWrapper.index
                  favDragContainer.draggingCode = favWrapper.modelData.code
                  favDragContainer.dragActive = true
                }
                onPositionChanged: (mouse) => {
                  if (!pressed || favDragContainer.draggingCode === "") return
                  var pos = mapToItem(favDragContainer, mouse.x, mouse.y)
                  var maxY = (KbLayoutState.favorites.length - 1) * 30
                  favDragContainer.dragY = Math.max(0, Math.min(maxY, pos.y - dragOffsetY))
                  favDragContainer.dragToIndex = Math.max(0, Math.min(KbLayoutState.favorites.length - 1, Math.round(favDragContainer.dragY / 30)))
                }
                onReleased: {
                  if (favDragContainer.draggingCode === "") return
                  var code = favDragContainer.draggingCode
                  var toIdx = favDragContainer.dragToIndex
                  favDragContainer.dragActive = false
                  favDragContainer.draggingCode = ""
                  favDragContainer.dragFromIndex = -1
                  favDragContainer.dragToIndex = -1
                  KbLayoutState.moveFavoriteByCode(code, toIdx)
                }
              }
            }
  
            KbLayoutRow {
              x: 22
              width: parent.width - 22
              height: parent.height
              code: favWrapper.modelData.code
              name: favWrapper.modelData.name
            }
          }
        }
      }
  
      // ── Divider ───────────────────────────────────────────────────────────────
      Rectangle {
        width: parent.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        visible: searchText === "" && KbLayoutState.layoutsLoaded
      }
  
      // ── All layouts header ────────────────────────────────────────────────────
      Item {
        width: parent.width; height: 26
        visible: KbLayoutState.layoutsLoaded
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: searchText === "" ? "ALL LAYOUTS" : "RESULTS"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      // Loading indicator
      Item {
        width: parent.width; height: 36
        visible: !KbLayoutState.layoutsLoaded
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "Loading layouts…"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }
  
      // Scrollable list
      Item {
        width: parent.width
        height: listView.contentHeight < 200 ? listView.contentHeight : 200
        visible: KbLayoutState.layoutsLoaded
        clip: true
  
        ListView {
          id: listView
          anchors.fill: parent
          model: root.filteredLayouts
          spacing: 0
          clip: true
  
          delegate: KbLayoutRow {
            required property var modelData
            width: listView.width
            code: modelData.code
            name: modelData.name
          }
  
          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
          }
        }
      }
  
      Item { width: parent.width; height: 8 }
    }
  
    onVisibleChanged: {
      if (visible) searchInput.forceActiveFocus()
      else searchInput.text = ""
    }
  }
  component SysInfoRow: Item {
    id: root
    property string label: ""
    property int pct: 0
    property string detail: ""
  
    width: parent ? parent.width : 260
    height: 44
  
    function barColor(p) {
      if (p >= 80) return Theme.activeRed
      if (p >= 60) return Theme.warning
      return Theme.accent
    }
  
    Text {
      anchors { left: parent.left; top: parent.top; topMargin: 4 }
      text: root.label
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: Theme.foreground; opacity: 0.7
      renderType: Text.NativeRendering
    }
  
    Text {
      anchors { right: parent.right; top: parent.top; topMargin: 4 }
      text: root.detail
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: root.barColor(root.pct)
      renderType: Text.NativeRendering
    }
  
    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 4 }
      height: 4
      radius: 2
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
  
      Rectangle {
        width: Math.max(4, parent.width * Math.min(root.pct, 100) / 100)
        height: parent.height
        radius: 2
        color: root.barColor(root.pct)
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
      }
    }
  }
  component SysInfoPopup: Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // Header
      Item {
        width: parent.width
        height: 42
  
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "SYSTEM"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
  
        Text {
          anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
          text: Glyphs.settings
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground
          opacity: settingsHov.containsMouse ? 0.9 : 0.35
          renderType: Text.NativeRendering
          HoverHandler { id: settingsHov }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              SysInfoState.hide()
              Quickshell.execDetached(["alacritty", "-e", "btop"])
            }
          }
        }
      }
  
      // Resource rows
      Column {
        id: rowsCol
        anchors { left: parent.left; right: parent.right }
        leftPadding: 14; rightPadding: 14; bottomPadding: 14
        spacing: 4
  
        SysInfoRow {
          width: parent.width - 28
          label: "CPU"
          pct: SysInfoState.cpu
          detail: {
            var s = SysInfoState.cpu + "%"
            if (SysInfoState.cpuTemp > 0) s += "  ·  " + SysInfoState.cpuTemp + "°C"
            return s
          }
        }
  
        SysInfoRow {
          width: parent.width - 28
          label: "RAM"
          pct: SysInfoState.ramPct
          detail: SysInfoState.ramPct + "%  ·  " + SysInfoState.ramUsed + " / " + SysInfoState.ramTotal + " GB"
        }
  
        SysInfoRow {
          visible: SysInfoState.gpu >= 0
          width: parent.width - 28
          label: "GPU"
          pct: SysInfoState.gpu >= 0 ? SysInfoState.gpu : 0
          detail: {
            var s = SysInfoState.gpu + "%"
            if (SysInfoState.gpuVramUsed >= 0)
              s += "  ·  " + SysInfoState.gpuVramUsed + "/" + SysInfoState.gpuVramTotal + " GB"
            if (SysInfoState.gpuTemp > 0) s += "  ·  " + SysInfoState.gpuTemp + "°C"
            return s
          }
        }
  
        Item {
          visible: SysInfoState.nvmeTemp > 0
          width: parent.width - 28
          height: 28
  
          Text {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: "NVMe"
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground; opacity: 0.7
            renderType: Text.NativeRendering
          }
  
          Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: SysInfoState.nvmeTemp + "°C"
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: SysInfoState.nvmeTemp >= 65 ? Theme.activeRed
                 : SysInfoState.nvmeTemp >= 55 ? Theme.warning
                 : Theme.foreground
            renderType: Text.NativeRendering
          }
        }
      }
    }
  }
  component BatteryRow: Item {
    id: root
    property string icon: ""
    property string label: ""
    property int pct: 0
    property bool charging: false

    width: parent ? parent.width : 260
    height: 44

    function barColor(p) {
      if (p <= 15) return Theme.activeRed
      if (p <= 30) return Theme.warning
      return Theme.accent
    }

    Text {
      id: ic
      anchors { left: parent.left; top: parent.top; topMargin: 2 }
      text: root.icon
      font.family: Theme.font; font.pixelSize: Theme.fontSize + 4
      color: Theme.foreground; opacity: 0.85
      renderType: Text.NativeRendering
    }

    Text {
      anchors { left: ic.right; leftMargin: 10; top: parent.top; topMargin: 4 }
      text: root.label
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: Theme.foreground; opacity: 0.7
      renderType: Text.NativeRendering
    }

    Text {
      anchors { right: parent.right; top: parent.top; topMargin: 4 }
      text: (root.charging ? Glyphs.charging + " " : "") + root.pct + "%"
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: root.charging ? Theme.foreground : root.barColor(root.pct)
      renderType: Text.NativeRendering
    }

    Rectangle {
      anchors { left: ic.right; leftMargin: 10; right: parent.right; bottom: parent.bottom; bottomMargin: 6 }
      height: 4
      radius: 2
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)

      Rectangle {
        width: Math.max(4, parent.width * Math.min(root.pct, 100) / 100)
        height: parent.height
        radius: 2
        color: root.barColor(root.pct)
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
      }
    }
  }
  component BatteryPopup: Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    readonly property var ld: UPower.displayDevice
    readonly property bool hasLaptop: ld && ld.isLaptopBattery

    function iconFor(kind) {
      return kind === "mouse"    ? Glyphs.mouse
           : kind === "keyboard" ? Glyphs.keyboard
           : kind === "earbuds"  ? Glyphs.paHeadphone
           : kind === "headset"  ? Glyphs.headset
           : Glyphs.batDefault[5]
    }

    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0

      Item {
        width: parent.width
        height: 42
        Text {
          anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
          text: "BATERÍAS"
          font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }
      }

      Column {
        anchors { left: parent.left; right: parent.right }
        leftPadding: 14; rightPadding: 14; bottomPadding: 14
        spacing: 4

        BatteryRow {
          visible: root.hasLaptop
          width: parent.width - 28
          icon: Glyphs.laptop
          label: "Notebook"
          pct: root.hasLaptop ? Math.max(0, Math.min(100, Math.round(root.ld.percentage))) : 0
          charging: root.hasLaptop
            && (root.ld.state === UPowerDeviceState.Charging
             || root.ld.state === UPowerDeviceState.PendingCharge
             || root.ld.state === UPowerDeviceState.FullyCharged)
        }

        Repeater {
          model: BatteryState.devs
          delegate: BatteryRow {
            required property var modelData
            width: parent.width - 28
            icon: root.iconFor(modelData.kind)
            label: modelData.label
            pct: modelData.pct
            charging: modelData.charging
          }
        }

        Text {
          visible: !root.hasLaptop && BatteryState.devs.length === 0
          width: parent.width - 28
          text: "Sin dispositivos con batería"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.5
          wrapMode: Text.WordWrap
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
