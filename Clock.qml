import QtQuick
import Quickshell

// Clock: "Sat 6  HH:mm  weather". Hover opens the calendar popup.
// Right-click opens timezone selector. Left-click on weather sends a notification.
Item {
  id: root
  property int pad: 10
  property var now: new Date()
  property string weatherText: ""

  implicitWidth: row.implicitWidth + 2 * pad
  implicitHeight: Theme.barHeight

  Row {
    id: row
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 1
    spacing: 7

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDateTime(root.now, "ddd d")
      font.family: Theme.font
      font.pixelSize: Theme.fontSize
      color: Theme.foreground
      opacity: 0.55
      renderType: Text.NativeRendering
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDateTime(root.now, "HH:mm")
      font.family: Theme.font
      font.pixelSize: Theme.fontSize + 2
      color: Theme.foreground
      renderType: Text.NativeRendering
    }

    Text {
      id: weatherLabel
      anchors.verticalCenter: parent.verticalCenter
      text: root.weatherText
      visible: root.weatherText.length > 0
      font.family: Theme.font
      font.pixelSize: Theme.fontSize
      color: Theme.foreground
      opacity: 0.55
      renderType: Text.NativeRendering

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["bash", "-c",
          "notify-send -u low \"$(omarchy-weather-status)\""])
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-tz-select"])
    onContainsMouseChanged: {
      if (containsMouse) {
        CalendarState.anchorX = root.mapToItem(null, 0, 0).x
        CalendarState.anchorW = root.width
        CalendarState.show()
      } else {
        CalendarState.hide()
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Poll {
    interval: 60000
    command: ["omarchy-weather-bar"]
    onUpdated: (out) => {
      try { root.weatherText = JSON.parse(out).text || "" }
      catch (e) { root.weatherText = "" }
    }
  }
}
