import QtQuick

// One section (Outputs or Inputs) in the AudioPopup — collapsable.
Item {
  id: root

  property string label: ""
  property var devices: []
  property bool collapsed: true
  signal activate(string name)

  visible: devices.length > 0
  height: headerItem.height + contentArea.height
  implicitHeight: height

  // ── Header (always visible, clickable to toggle) ─────────────────────
  Item {
    id: headerItem
    width: parent.width
    height: 26

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.collapsed = !root.collapsed
    }

    Text {
      id: chevron
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      text: "›"
      font.family: Theme.font
      font.pixelSize: Theme.fontSize + 3
      color: Theme.foreground
      opacity: headerHov.containsMouse ? 0.7 : 0.4
      renderType: Text.NativeRendering
      rotation: root.collapsed ? 0 : 90
      transformOrigin: Item.Center
      Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.InOutQuad } }
    }
    HoverHandler { id: headerHov }

    Text {
      anchors { left: chevron.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
      text: root.label
      font.family: Theme.font
      font.pixelSize: Theme.fontSize + 2
      color: Theme.foreground
      opacity: 0.7
      renderType: Text.NativeRendering
    }
  }

  // ── Content (animated collapse) ───────────────────────────────────────
  Item {
    id: contentArea
    anchors { top: headerItem.bottom; left: parent.left; right: parent.right }
    height: root.collapsed ? 0 : contentCol.implicitHeight
    clip: true
    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.InOutQuad } }

    Column {
      id: contentCol
      width: parent.width
      spacing: 0

      Repeater {
        model: root.devices

        delegate: Item {
          id: row
          required property var modelData
          width: root.width
          height: 30

          readonly property bool isActive: modelData.active === true

          MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activate(row.modelData.name)
          }

          Rectangle {
            anchors.fill: parent
            color: row.isActive
              ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
              : ma.containsMouse
                ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.18)
                : "transparent"
          }

          Text {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: "▶"
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            color: Theme.accent
            visible: row.isActive
            renderType: Text.NativeRendering
          }

          Text {
            anchors {
              left: parent.left; leftMargin: 32
              right: parent.right; rightMargin: 14
              verticalCenter: parent.verticalCenter
            }
            text: row.modelData.desc || row.modelData.name
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: row.isActive ? Theme.accent : Theme.foreground
            opacity: row.isActive ? 1.0 : (ma.containsMouse ? 1.0 : 0.7)
            elide: Text.ElideRight
            renderType: Text.NativeRendering
          }
        }
      }

      Item { width: parent.width; height: 8 }
    }
  }
}
