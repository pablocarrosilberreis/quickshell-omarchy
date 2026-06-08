import QtQuick

Rectangle {
  id: root

  property bool popupVisible: false

  radius: 12
  color: Qt.darker(Theme.background, 1.8)
  border.color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
  border.width: 1

  opacity: 0
  property real _slideY: -10
  transform: Translate { y: root._slideY }

  onPopupVisibleChanged: if (popupVisible) _enterAnim.start()

  ParallelAnimation {
    id: _enterAnim
    NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "_slideY"; from: -10; to: 0; duration: 140; easing.type: Easing.OutCubic }
  }
}
