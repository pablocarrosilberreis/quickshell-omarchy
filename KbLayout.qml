import QtQuick
import Quickshell

BarButton {
  id: root
  pad: 10
  text: KbLayoutState.currentLayout
  tooltipText: "Click to switch · Right-click to browse layouts"
  onLeftClicked: {
    KbLayoutState.anchorX = root.mapToItem(null, 0, 0).x
    KbLayoutState.anchorW = root.width
    KbLayoutState.toggle()
  }
}
