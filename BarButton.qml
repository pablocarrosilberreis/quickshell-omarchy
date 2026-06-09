import QtQuick
import Quickshell

// A single text/glyph bar module with click/scroll handling and a tooltip.
// Hidden automatically when its text is empty (mirrors waybar hiding empty
// custom modules).
Item {
  id: root

  property string text: ""
  property color color: Theme.foreground
  property string fontFamily: Theme.font
  property int fontSize: Theme.fontSize
  property int pad: 6

  property string tooltipText: ""
  property bool bgVisible: false
  // True while the pointer is over this module (for hover-driven popups).
  property alias hovered: mouse.containsMouse
  property string leftCmd: ""
  property string rightCmd: ""
  property string middleCmd: ""
  property string scrollUpCmd: ""
  property string scrollDownCmd: ""

  signal leftClicked()
  signal rightClicked()
  signal scrolledUp()
  signal scrolledDown()

  visible: root.text.length > 0
  implicitWidth: label.implicitWidth + 2 * pad
  implicitHeight: Theme.barHeight

  function exec(cmd) {
    if (cmd && cmd.length > 0)
      Quickshell.execDetached(["bash", "-c", cmd])
  }

  Rectangle {
    visible: root.bgVisible
    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
    height: parent.height - 6
    radius: height / 2
    color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
    border.width: 1
    border.color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.18)
  }

  Text {
    id: label
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 0
    text: root.text
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    // NativeRendering: distance-field rendering fails for some fonts (e.g. the
    // tiny omarchy logo font), showing tofu boxes.
    renderType: Text.NativeRendering
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor

    onClicked: (m) => {
      if (m.button === Qt.LeftButton) { root.exec(root.leftCmd); root.leftClicked() }
      else if (m.button === Qt.RightButton) { root.exec(root.rightCmd); root.rightClicked() }
      else if (m.button === Qt.MiddleButton) { root.exec(root.middleCmd) }
    }
    onWheel: (w) => {
      if (w.angleDelta.y > 0) { root.exec(root.scrollUpCmd); root.scrolledUp() }
      else if (w.angleDelta.y < 0) { root.exec(root.scrollDownCmd); root.scrolledDown() }
    }

    Tooltip {
      hostItem: root
      text: root.tooltipText
      visible: mouse.containsMouse && root.tooltipText.length > 0
    }
  }
}
