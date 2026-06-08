import QtQuick

// Compact bar item: shows only the track title; hovering triggers the detail popup.
Item {
  id: root

  visible: MediaPlayerState.active
  implicitWidth: MediaPlayerState.active ? (row.implicitWidth + 22) : 0
  implicitHeight: Theme.barHeight
  clip: true

  Row {
    id: row
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: -8
    spacing: 7

    // App icon — falls back to a music note glyph when no icon is found
    Item {
      width: 15; height: 15
      anchors.verticalCenter: parent.verticalCenter

      Image {
        id: appIcon
        anchors.fill: parent
        source: MediaPlayerState.appIconPath
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
        smooth: true
      }
      Text {
        anchors.centerIn: parent
        text: "♫"
        font.family: Theme.font
        font.pixelSize: 10
        color: Theme.foreground
        opacity: 0.6
        visible: appIcon.status !== Image.Ready
        renderType: Text.NativeRendering
      }
    }

    Text {
      text: MediaPlayerState.trackTitle
      font.family: Theme.font
      font.pixelSize: Theme.fontSize - 1
      color: Theme.foreground
      elide: Text.ElideRight
      width: Math.min(implicitWidth, 180)
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: 1
      renderType: Text.NativeRendering
    }
  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered) {
        MediaPlayerState.anchorX = root.mapToItem(null, 0, 0).x
        MediaPlayerState.anchorW = root.width
        MediaPlayerState.show()
      } else {
        MediaPlayerState.hide()
      }
    }
  }
}
