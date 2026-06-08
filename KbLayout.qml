import QtQuick
import Quickshell

BarButton {
  id: root
  pad: 10
  text: KbLayoutState.currentLayout
  tooltipText: KbLayoutState.currentLayoutName
  onLeftClicked: {
    KbLayoutState.anchorX = root.mapToItem(null, 0, 0).x
    KbLayoutState.anchorW = root.width
    KbLayoutState.toggle()
  }
}
