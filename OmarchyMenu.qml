import QtQuick
import QtQuick.Effects
import Quickshell

// Omarchy menu button. Uses a tinted PNG of the omarchy mark, since Qt's text
// renderer won't draw the omarchy logo font's glyph (works in Waybar/GTK only).
Item {
  id: root
  property int pad: 8
  property int iconSize: 15
  implicitWidth: iconSize + 2 * pad
  implicitHeight: Theme.barHeight

  Image {
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize
    sourceSize.width: root.iconSize * 2
    sourceSize.height: root.iconSize * 2
    source: Qt.resolvedUrl("assets/omarchy-mark.png")
    smooth: true
    layer.enabled: true
    layer.effect: MultiEffect {
      colorization: 1.0
      colorizationColor: Theme.foreground
      brightness: 1.0
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: (m) => {
      if (m.button === Qt.LeftButton) Quickshell.execDetached(["omarchy-menu"])
      else if (m.button === Qt.RightButton) Quickshell.execDetached(["xdg-terminal-exec"])
    }
    Tooltip {
      hostItem: root
      text: "Omarchy Menu\n\nSuper + Alt + Space"
      visible: mouse.containsMouse
    }
  }
}
