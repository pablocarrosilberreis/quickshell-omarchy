import QtQuick

// Floating pill container. Children are centered inside the full barHeight
// area; the visible Rectangle is shorter, giving the floating pill look.
// Hides automatically when all children are invisible.
Item {
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
