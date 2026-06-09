import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Calendar popup content: full time + date with seconds, month grid, and weather.
Item {

  // ── inline sub-components ──────────────────────────────────────────────
  component NotifCenter: Item {
    id: root
    implicitWidth: 380
    implicitHeight: headerRow.implicitHeight
      + (hasNotifs
          ? clearBtn.implicitHeight + 4 + Math.min(listCol.implicitHeight, 220) + 8
          : emptyText.implicitHeight + 8)
  
    readonly property bool hasNotifs: NotifState.notifications.length > 0
  
    // ── Header ──────────────────────────────────────────────────────────────
    Item {
      id: headerRow
      width: parent.width
      implicitHeight: 18
  
      // "Notifications" label
      Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: "Notifications"
        font.family: Theme.font; font.pixelSize: 11
        color: Theme.foreground; opacity: 0.4
        renderType: Text.NativeRendering
      }
  
      // DND toggle slider (top-right)
      Item {
        id: dndToggle
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 28; height: 16
  
        Rectangle {
          anchors.fill: parent
          radius: height / 2
          color: NotifState.muted
            ? Qt.rgba(Theme.activeRed.r, Theme.activeRed.g, Theme.activeRed.b, 0.85)
            : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85)
          Behavior on color { ColorAnimation { duration: 150 } }
        }
  
        Rectangle {
          width: 12; height: 12
          radius: 6
          color: "white"
          anchors.verticalCenter: parent.verticalCenter
          x: NotifState.muted ? 2 : parent.width - width - 2
          Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
        }
  
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: NotifState.toggleMute()
        }
      }
  
      // Bell icon — left of the slider
      Text {
        anchors { right: dndToggle.left; rightMargin: 6; verticalCenter: parent.verticalCenter; verticalCenterOffset: 1 }
        text: NotifState.muted ? Glyphs.notifBellOff : Glyphs.notifBell
        font.family: Theme.font; font.pixelSize: 11
        color: NotifState.muted ? Theme.activeRed : Theme.foreground
        opacity: NotifState.muted ? 1.0 : 0.4
        renderType: Text.NativeRendering
      }
    }
  
    // "Clear all" — on its own line below the bell icon + DND slider.
    Text {
      id: clearBtn
      visible: root.hasNotifs
      anchors { top: headerRow.bottom; topMargin: 4; right: parent.right }
      text: "Clear all"
      font.family: Theme.font; font.pixelSize: 11
      color: Theme.foreground; opacity: 0.4
      renderType: Text.NativeRendering
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: NotifState.clearAll()
      }
    }
  
    // ── Empty state ─────────────────────────────────────────────────────────
    Text {
      id: emptyText
      visible: !root.hasNotifs
      anchors { top: headerRow.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
      text: "No notifications"
      font.family: Theme.font; font.pixelSize: 11
      color: Theme.foreground; opacity: 0.3
      renderType: Text.NativeRendering
    }
  
    // ── List ─────────────────────────────────────────────────────────────────
    Item {
      visible: root.hasNotifs
      anchors { top: clearBtn.bottom; topMargin: 8; left: parent.left; right: parent.right }
      height: Math.min(listCol.implicitHeight, 220)
      clip: true
  
      Column {
        id: listCol
        width: parent.width
        spacing: 6
  
        Repeater {
          // ScriptModel diffs the array and emits granular row inserts/removes
          // instead of a full reset, so the Repeater never calls regenerate()
          // (which segfaulted Qt's QML incubator when the whole array was
          // reassigned on each incoming notification).
          model: ScriptModel { values: NotifState.notifications }
  
          delegate: Rectangle {
            required property var modelData
            required property int index
            // modelData can briefly turn null if its Notification QObject is
            // destroyed; collapse and guard everything against that.
            visible: modelData != null
            width: listCol.width
            implicitHeight: modelData != null ? itemContent.implicitHeight + 16 : 0
            radius: 8
            color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.05)
  
            Column {
              id: itemContent
              anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; rightMargin: 28 }
              spacing: 2
  
              Text {
                text: NotifState.sourceLabel(modelData)
                font.family: Theme.font; font.pixelSize: 9
                color: Theme.foreground; opacity: 0.4
                renderType: Text.NativeRendering
              }
              Text {
                width: parent.width
                wrapMode: Text.Wrap
                text: NotifState.title(modelData)
                font.family: Theme.font; font.pixelSize: 12; font.bold: true
                color: Theme.foreground
                renderType: Text.NativeRendering
              }
              Text {
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                visible: text.length > 0
                text: NotifState.subtitle(modelData)
                font.family: Theme.font; font.pixelSize: 11
                color: Theme.foreground; opacity: 0.6
                renderType: Text.NativeRendering
              }
            }
  
            MouseArea {
              anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 28 }
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!modelData) return
                if ((modelData.summary || "").indexOf("Screenshot") >= 0) {
                  Quickshell.execDetached(["bash", "-c",
                    "f=$(ls -t ~/Pictures/screenshot-*.png 2>/dev/null | head -1); [ -n \"$f\" ] && satty --filename \"$f\" --output-filename \"$f\" --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy"])
                }
                var acts = modelData.actions || []
                for (var i = 0; i < acts.length; i++) {
                  if (acts[i].identifier === "default") { try { acts[i].invoke() } catch (e) {} break }
                }
                NotifState.dismiss(modelData)
              }
            }
  
            Text {
              anchors { right: parent.right; bottom: itemContent.bottom; rightMargin: 8; bottomMargin: 0 }
              text: modelData ? (modelData.receivedAt || "") : ""
              font.family: Theme.font; font.pixelSize: 9
              color: Theme.foreground; opacity: 0.85
              renderType: Text.NativeRendering
            }
  
            Text {
              anchors { right: parent.right; top: parent.top; margins: 8 }
              text: "✕"
              font.pixelSize: 11
              color: Theme.foreground; opacity: 0.4
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotifState.dismiss(modelData)
              }
            }
          }
        }
      }
    }
  }

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
