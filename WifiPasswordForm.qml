import QtQuick
import Quickshell

Item {
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
