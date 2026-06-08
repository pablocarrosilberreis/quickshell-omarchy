import QtQuick
import Quickshell
import Quickshell.Wayland

// Reusable anchored popup: a full-screen overlay PanelWindow with click-outside
// dismissal and a PopupFrame positioned below the bar widget that opened it.
// The popup content is the default child and is placed inside the frame, e.g.:
//
//   PopupPanel {
//     shown: WifiState.visible
//     ns: "quickshell-wifi"
//     anchorX: WifiState.anchorX; anchorW: WifiState.anchorW
//     screenWidth: modelData.width
//     onDismissed: WifiState.hide()
//     WifiPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
//   }
//
// The frame auto-sizes to its content (content top margin + height + bottomPadding).
PanelWindow {
  id: root

  property bool shown: false
  property real anchorX: 0
  property real anchorW: 0
  property real screenWidth: 0
  property int popupWidth: 300
  property string ns: "quickshell-popup"
  property int popupKeyboardFocus: WlrKeyboardFocus.None
  property real frameRadius: Theme.windowRadius
  property int bottomPadding: 10
  signal dismissed()

  // Content is added to the frame (its parent is the frame).
  default property alias content: frame.data

  // Keep the window alive until the frame's close animation finishes.
  visible: frame.active
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusiveZone: -1
  WlrLayershell.namespace: root.ns
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.popupKeyboardFocus
  WlrLayershell.margins.top: Theme.barHeight

  // Internal children assigned explicitly so they don't land in the
  // `content` default-property alias above.
  data: [
    MouseArea { anchors.fill: parent; z: 0; onClicked: root.dismissed() },
    PopupFrame {
      id: frame
      popupVisible: root.shown
      z: 1
      x: Math.max(4, Math.min(
        root.anchorX + root.anchorW / 2 - root.popupWidth / 2,
        root.screenWidth - root.popupWidth - 4))
      y: Theme.popupGap
      width: root.popupWidth
      radius: root.frameRadius
      implicitHeight: frame.childrenRect.y + frame.childrenRect.height + root.bottomPadding
    }
  ]
}
