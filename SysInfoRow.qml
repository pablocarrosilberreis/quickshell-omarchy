import QtQuick

Item {
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
