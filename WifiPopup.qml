import QtQuick
import Quickshell

Item {
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
