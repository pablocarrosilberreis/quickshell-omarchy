import QtQuick
import Quickshell.Hyprland

// Workspaces as circles: ● filled when occupied or focused, ○ empty otherwise.
// Always shows 1..3; shows extra workspaces only if they exist (have windows
// or are currently focused).
Row {
  id: root
  spacing: 6

  function buildIds() {
    var ids = {1: true, 2: true, 3: true}
    var list = Hyprland.workspaces.values
    for (var j = 0; j < list.length; j++) {
      var id = list[j].id
      if (id > 0) ids[id] = true
    }
    var arr = []
    for (var k in ids) arr.push(parseInt(k))
    arr.sort(function(a, b) { return a - b })
    return arr
  }

  property var ids: buildIds()

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() { root.ids = root.buildIds() }
  }

  Repeater {
    model: root.ids

    delegate: Component {
      Item {
        id: ws
        required property int modelData

        readonly property bool focused: Hyprland.focusedWorkspace
          && Hyprland.focusedWorkspace.id === modelData
        readonly property bool exists: {
          var v = Hyprland.workspaces.values
          for (var i = 0; i < v.length; i++)
            if (v[i].id === modelData) return true
          return false
        }

        implicitWidth: 18
        implicitHeight: Theme.barHeight

        Text {
          anchors.centerIn: parent
          text: ws.exists ? "●" : "○"
          font.family: Theme.font
          font.pixelSize: ws.focused ? 20 : 17
          color: ws.focused ? Theme.accent : Theme.foreground
          opacity: ws.focused ? 1.0 : ws.exists ? 0.7 : 0.3
          renderType: Text.NativeRendering
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Hyprland.dispatch("workspace", "" + modelData)
        }
      }
    }
  }
}
