import QtQuick

// Framed popup background with Apple-style open/close motion: fade + a gentle
// spring scale that grows from the top (where the popup attaches under the bar),
// plus a quick fade-and-shrink on close.
//
// `active` stays true from the moment the popup opens until the close animation
// finishes — parents should bind their window's `visible` to it so the close
// animation is actually shown (the window must outlive popupVisible going false).
Rectangle {
  id: root

  property bool popupVisible: false
  readonly property bool active: _open || _closing
  property bool _open: false
  property bool _closing: false

  radius: Theme.windowRadius
  color: Qt.darker(Theme.background, 1.8)

  // Hidden resting state; grow from the top edge.
  opacity: 0
  scale: 0.9
  transformOrigin: Item.Top
  property real _slideY: -8
  transform: Translate { y: root._slideY }

  // If created while already visible (rare), claim the window without animating.
  Component.onCompleted: if (popupVisible) _open = true

  onPopupVisibleChanged: {
    if (popupVisible) {
      _closing = false
      _open = true
      exitAnim.stop()
      enterAnim.restart()
    } else if (_open) {
      _open = false
      _closing = true
      enterAnim.stop()
      exitAnim.restart()
    }
  }

  // Open: fade in, slide down, and a soft spring-scale with a small overshoot.
  ParallelAnimation {
    id: enterAnim
    NumberAnimation { target: root; property: "opacity"; from: 0;    to: 1; duration: 160; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "_slideY"; from: -8;   to: 0; duration: 220; easing.type: Easing.OutCubic }
    NumberAnimation {
      target: root; property: "scale"; from: 0.9; to: 1
      duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1
    }
  }

  // Close: quick fade + shrink, then release the window.
  ParallelAnimation {
    id: exitAnim
    NumberAnimation { target: root; property: "opacity"; to: 0;    duration: 130; easing.type: Easing.InCubic }
    NumberAnimation { target: root; property: "_slideY"; to: -6;   duration: 130; easing.type: Easing.InCubic }
    NumberAnimation { target: root; property: "scale";   to: 0.94; duration: 130; easing.type: Easing.InCubic }
    onFinished: root._closing = false
  }
}
