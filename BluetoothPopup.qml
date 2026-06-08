import QtQuick
import Quickshell

Item {
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
