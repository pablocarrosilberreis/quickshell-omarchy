import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification history list shown inside the calendar popup.
Item {
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
              text: modelData ? modelData.summary : ""
              font.family: Theme.font; font.pixelSize: 12; font.bold: true
              color: Theme.foreground
              renderType: Text.NativeRendering
            }
            Text {
              width: parent.width
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
              visible: modelData && modelData.body ? modelData.body.length > 0 : false
              text: modelData && modelData.body ? modelData.body : ""
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
