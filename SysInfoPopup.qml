import QtQuick
import Quickshell

Item {
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
