import QtQuick
import Quickshell

Item {

  // ── inline sub-components ──────────────────────────────────────────────
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
