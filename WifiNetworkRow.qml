import QtQuick
import Quickshell

Item {
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
