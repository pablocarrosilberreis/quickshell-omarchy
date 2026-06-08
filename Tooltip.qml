import QtQuick
import Quickshell

// Hover tooltip shown below a bar item.
PopupWindow {
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
