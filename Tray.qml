import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// System tray: render items, left-click activate, right-click context menu.
Row {
  id: root
  spacing: 14

  Repeater {
    model: SystemTray.items

    delegate: Item {
      id: entry
      required property var modelData
      width: 16
      height: Theme.barHeight

      Image {
        id: icon
        anchors.centerIn: parent
        width: 14
        height: 14
        sourceSize.width: 14
        sourceSize.height: 14
        smooth: true
        source: entry.modelData.icon
      }

      MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => {
          if (m.button === Qt.LeftButton) {
            entry.modelData.activate()
          } else if (m.button === Qt.MiddleButton) {
            entry.modelData.secondaryActivate()
          } else if (m.button === Qt.RightButton && entry.modelData.hasMenu) {
            menuAnchor.open()
          }
        }

        Tooltip {
          hostItem: entry
          text: entry.modelData.tooltipTitle || entry.modelData.title || ""
          visible: mouse.containsMouse && (entry.modelData.tooltipTitle || entry.modelData.title)
        }
      }

      QsMenuAnchor {
        id: menuAnchor
        menu: entry.modelData.menu
        anchor.item: entry
        anchor.rect.y: entry.height
      }
    }
  }
}
