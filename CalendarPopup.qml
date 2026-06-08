import QtQuick

// Calendar popup content: full time + date with seconds, month grid, and weather.
Item {
  id: root
  property var now: new Date()
  property int viewYear: now.getFullYear()
  property int viewMonth: now.getMonth()

  readonly property var monthNames: [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ]
  readonly property var dayNames: ["Mo","Tu","We","Th","Fr","Sa","Su"]

  function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
  // Monday-first: 0=Mon … 6=Sun
  function firstWeekday(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7 }

  function weatherIcon(code) {
    if (code === 113) return "☀️"
    if (code === 116) return "⛅"
    if (code === 119 || code === 122) return "☁️"
    if (code === 143 || code === 248 || code === 260) return "🌫️"
    if ([200,386,389,392,395].indexOf(code) >= 0) return "⛈️"
    if ([179,182,185,281,284,311,314,317,320,323,326,329,332,335,338,350,362,365,368,371,374,377].indexOf(code) >= 0) return "❄️"
    if ([176,263,266,293,296,299,302,305,308,353,356,359].indexOf(code) >= 0) return "🌧️"
    return "🌡️"
  }

  // Only tick the seconds clock while the calendar is actually shown.
  Timer { interval: 1000; running: CalendarState.visible; repeat: true; onTriggered: root.now = new Date() }

  // Reset view to current month when popup opens
  Connections {
    target: CalendarState
    function onVisibleChanged() {
      if (CalendarState.visible) {
        root.viewYear  = root.now.getFullYear()
        root.viewMonth = root.now.getMonth()
      }
    }
  }

  implicitHeight: mainColumn.implicitHeight
  implicitWidth: mainColumn.implicitWidth

  Column {
    id: mainColumn
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    spacing: 10

    // ── Time ──────────────────────────────────────────────────────────────
    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 3

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(root.now, "HH:mm:ss")
        font.family: Theme.font
        font.pixelSize: 28
        color: Theme.foreground
        renderType: Text.NativeRendering
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(root.now, "dddd, d MMMM yyyy")
        font.family: Theme.font
        font.pixelSize: 11
        color: Theme.foreground
        opacity: 0.6
        renderType: Text.NativeRendering
      }
    }

    // Separator
    Rectangle {
      width: mainRow.implicitWidth; height: 1
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
    }

    // ── Calendar + Weather side by side ───────────────────────────────────
    Row {
      id: mainRow
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 0

      // ── Calendar ────────────────────────────────────────────────────────
      Column {
        id: calColumn
        spacing: 6

        // Month nav
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 0

          Text {
            text: "‹"
            font.family: Theme.font
            font.pixelSize: 16
            color: Theme.foreground
            width: 28; height: 20
            horizontalAlignment: Text.AlignHCenter
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                CalendarState.show()
                root.viewMonth--
                if (root.viewMonth < 0) { root.viewMonth = 11; root.viewYear-- }
              }
            }
          }

          Text {
            text: root.monthNames[root.viewMonth] + "  " + root.viewYear
            font.family: Theme.font
            font.pixelSize: 12
            color: Theme.foreground
            width: 160; height: 20
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
          }

          Text {
            text: "›"
            font.family: Theme.font
            font.pixelSize: 16
            color: Theme.foreground
            width: 28; height: 20
            horizontalAlignment: Text.AlignHCenter
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                CalendarState.show()
                root.viewMonth++
                if (root.viewMonth > 11) { root.viewMonth = 0; root.viewYear++ }
              }
            }
          }
        }

        // Weekday headers
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          Repeater {
            model: root.dayNames
            Text {
              width: 28; height: 16
              text: modelData
              font.family: Theme.font
              font.pixelSize: 9
              color: Theme.foreground
              opacity: 0.4
              horizontalAlignment: Text.AlignHCenter
              renderType: Text.NativeRendering
            }
          }
        }

        // Day cells
        Grid {
          anchors.horizontalCenter: parent.horizontalCenter
          columns: 7
          rowSpacing: 2
          columnSpacing: 2

          Repeater {
            model: root.firstWeekday(root.viewYear, root.viewMonth)
                   + root.daysInMonth(root.viewYear, root.viewMonth)

            delegate: Item {
              width: 28; height: 24

              readonly property int offset: root.firstWeekday(root.viewYear, root.viewMonth)
              readonly property bool isDay: index >= offset
              readonly property int dayNum: index - offset + 1
              readonly property bool isToday: isDay
                && dayNum === root.now.getDate()
                && root.viewMonth === root.now.getMonth()
                && root.viewYear === root.now.getFullYear()

              Rectangle {
                anchors.centerIn: parent
                width: 24; height: 24; radius: 12
                color: Theme.accent
                visible: parent.isToday
              }

              Text {
                anchors.centerIn: parent
                text: parent.isDay ? ("" + parent.dayNum) : ""
                font.family: Theme.font
                font.pixelSize: 11
                color: parent.isToday ? Theme.background : Theme.foreground
                opacity: parent.isToday ? 1.0 : 0.8
                renderType: Text.NativeRendering
              }
            }
          }
        }
      }

      // ── Vertical divider ────────────────────────────────────────────────
      Item {
        visible: CalendarState.weather !== null
        width: 17
        implicitHeight: calColumn.implicitHeight
        Rectangle {
          anchors.centerIn: parent
          width: 1; height: parent.height
          color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
        }
      }

      // ── Weather ─────────────────────────────────────────────────────────
      Item {
        id: weatherItem
        visible: CalendarState.weather !== null
        implicitWidth: 170
        implicitHeight: calColumn.implicitHeight

        Column {
          id: weatherInner
          anchors.centerIn: parent
          width: 154  // weatherItem.implicitWidth - 16 padding
          spacing: 14

          // Today
          Column {
            width: parent.width
            spacing: 6

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 8

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: CalendarState.weather ? root.weatherIcon(CalendarState.weather.current.code) : ""
                font.pixelSize: 30
                renderType: Text.NativeRendering
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: CalendarState.weather ? (CalendarState.weather.current.temp + "°C") : ""
                font.family: Theme.font
                font.pixelSize: 30
                color: Theme.foreground
                renderType: Text.NativeRendering
              }
            }

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: CalendarState.weather ? CalendarState.weather.current.desc : ""
              font.family: Theme.font
              font.pixelSize: 13
              color: Theme.foreground
              opacity: 0.7
              renderType: Text.NativeRendering
            }

            Text {
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: CalendarState.weather
                ? ("Feels " + CalendarState.weather.current.feelsLike + "°  ·  " + Glyphs.humidity + " "
                   + CalendarState.weather.current.humidity + " %")
                : ""
              font.family: Theme.font
              font.pixelSize: 11
              color: Theme.foreground
              opacity: 0.5
              renderType: Text.NativeRendering
            }
          }

          // 3-day forecast
          Column {
            width: parent.width
            spacing: 8

            Repeater {
              model: CalendarState.weather ? CalendarState.weather.days : []
              delegate: Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                  width: 36
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.dayName
                  font.family: Theme.font
                  font.pixelSize: 13
                  color: Theme.foreground
                  opacity: 0.5
                  renderType: Text.NativeRendering
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.weatherIcon(modelData.code)
                  font.pixelSize: 16
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.max + "° / " + modelData.min + "°"
                  font.family: Theme.font
                  font.pixelSize: 13
                  color: Theme.foreground
                  opacity: 0.7
                  renderType: Text.NativeRendering
                }
              }
            }
          }
        }
      }
    }

    // ── Notification center ───────────────────────────────────────────────
    Rectangle {
      width: mainRow.implicitWidth; height: 1
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
    }

    NotifCenter {
      implicitWidth: mainRow.implicitWidth
    }
  }
}
