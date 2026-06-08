import QtQuick

Item {
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
