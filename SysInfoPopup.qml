import QtQuick
import Quickshell

Item {

  // ── inline sub-components ──────────────────────────────────────────────
  component SysInfoRow: Item {
    id: root
    property string label: ""
    property int pct: 0
    property string detail: ""
  
    width: parent ? parent.width : 260
    height: 44
  
    function barColor(p) {
      if (p >= 80) return Theme.activeRed
      if (p >= 60) return Theme.warning
      return Theme.accent
    }
  
    Text {
      anchors { left: parent.left; top: parent.top; topMargin: 4 }
      text: root.label
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: Theme.foreground; opacity: 0.7
      renderType: Text.NativeRendering
    }
  
    Text {
      anchors { right: parent.right; top: parent.top; topMargin: 4 }
      text: root.detail
      font.family: Theme.font; font.pixelSize: Theme.fontSize
      color: root.barColor(root.pct)
      renderType: Text.NativeRendering
    }
  
    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 4 }
      height: 4
      radius: 2
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
  
      Rectangle {
        width: Math.max(4, parent.width * Math.min(root.pct, 100) / 100)
        height: parent.height
        radius: 2
        color: root.barColor(root.pct)
        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
      }
    }
  }

  id: root
  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight

  Column {
    id: col
    anchors { left: parent.left; right: parent.right; top: parent.top }
    spacing: 0

    // Header
    Item {
      width: parent.width
      height: 42

      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: "SYSTEM"
        font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground; opacity: 0.7
        renderType: Text.NativeRendering
      }

      Text {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: Glyphs.settings
        font.family: Theme.font; font.pixelSize: Theme.fontSize
        color: Theme.foreground
        opacity: settingsHov.containsMouse ? 0.9 : 0.35
        renderType: Text.NativeRendering
        HoverHandler { id: settingsHov }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            SysInfoState.hide()
            Quickshell.execDetached(["alacritty", "-e", "btop"])
          }
        }
      }
    }

    // Resource rows
    Column {
      id: rowsCol
      anchors { left: parent.left; right: parent.right }
      leftPadding: 14; rightPadding: 14; bottomPadding: 14
      spacing: 4

      SysInfoRow {
        width: parent.width - 28
        label: "CPU"
        pct: SysInfoState.cpu
        detail: {
          var s = SysInfoState.cpu + "%"
          if (SysInfoState.cpuTemp > 0) s += "  ·  " + SysInfoState.cpuTemp + "°C"
          return s
        }
      }

      SysInfoRow {
        width: parent.width - 28
        label: "RAM"
        pct: SysInfoState.ramPct
        detail: SysInfoState.ramPct + "%  ·  " + SysInfoState.ramUsed + " / " + SysInfoState.ramTotal + " GB"
      }

      SysInfoRow {
        visible: SysInfoState.gpu >= 0
        width: parent.width - 28
        label: "GPU"
        pct: SysInfoState.gpu >= 0 ? SysInfoState.gpu : 0
        detail: {
          var s = SysInfoState.gpu + "%"
          if (SysInfoState.gpuVramUsed >= 0)
            s += "  ·  " + SysInfoState.gpuVramUsed + "/" + SysInfoState.gpuVramTotal + " GB"
          if (SysInfoState.gpuTemp > 0) s += "  ·  " + SysInfoState.gpuTemp + "°C"
          return s
        }
      }

      Item {
        visible: SysInfoState.nvmeTemp > 0
        width: parent.width - 28
        height: 28

        Text {
          anchors { left: parent.left; verticalCenter: parent.verticalCenter }
          text: "NVMe"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.7
          renderType: Text.NativeRendering
        }

        Text {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          text: SysInfoState.nvmeTemp + "°C"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: SysInfoState.nvmeTemp >= 65 ? Theme.activeRed
               : SysInfoState.nvmeTemp >= 55 ? Theme.warning
               : Theme.foreground
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
