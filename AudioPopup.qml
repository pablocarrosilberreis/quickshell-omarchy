import QtQuick
import Quickshell

// Audio popup: app mixer on top, collapsable device sections below.
Item {
  id: root

  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight

  Column {
    id: col
    anchors { left: parent.left; right: parent.right; top: parent.top }
    spacing: 0

    // ── Header row (title + settings button) ─────────────────────────────
    Item {
      width: parent.width
      height: 30

      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: "Mixer"
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        font.bold: true
        color: Theme.foreground
        opacity: 0.85
        renderType: Text.NativeRendering
      }

      Text {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: Glyphs.settings
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.foreground
        opacity: settingsHov.containsMouse ? 0.9 : 0.35
        renderType: Text.NativeRendering
        HoverHandler { id: settingsHov }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            AudioState.hide()
            Quickshell.execDetached(["omarchy-launch-audio"])
          }
        }
      }
    }

    // ── App Mixer ────────────────────────────────────────────────────────
    AppMixer {
      width: parent.width
    }

    // Separator
    Rectangle {
      width: parent.width; height: 1
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
      visible: AudioState.sinks.length > 0 || AudioState.sources.length > 0
    }

    // ── Outputs ──────────────────────────────────────────────────────────
    AudioSection {
      width: parent.width
      label: "OUTPUTS"
      devices: AudioState.sinks
      onActivate: (name) => AudioState.setDefaultSink(name)
    }

    // Separator
    Rectangle {
      width: parent.width; height: 1
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
      visible: AudioState.sinks.length > 0 && AudioState.sources.length > 0
    }

    // ── Inputs ───────────────────────────────────────────────────────────
    AudioSection {
      width: parent.width
      label: "INPUTS"
      devices: AudioState.sources
      onActivate: (name) => AudioState.setDefaultSource(name)
    }
  }
}
