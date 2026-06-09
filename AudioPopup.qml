import QtQuick
import Quickshell
import Quickshell.Io

// Audio popup: app mixer on top, collapsable device sections below.
Item {

  // ── inline sub-components ──────────────────────────────────────────────
  component AudioSection: Item {
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
  component AppMixer: Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight
  
    property var streams: []
    property real masterVol: 1.0
    property bool masterMuted: false
    property bool dragging: false
  
    function refresh() { if (!dragging && !streamsProc.running) streamsProc.running = true }
  
    Timer {
      interval: 2000
      running: AudioState.visible
      repeat: true
      triggeredOnStart: true
      onTriggered: root.refresh()
    }
  
    Process {
      id: streamsProc
      command: ["omarchy-audio-streams"]
      stdout: StdioCollector { id: streamsBuf }
      onExited: (code) => {
        if (code !== 0) return
        try {
          // StdioCollector accumulates across runs — always use the last non-empty line
          var lines = streamsBuf.text.split('\n').filter(function(l) { return l.trim().length > 0 })
          var last = lines.length > 0 ? lines[lines.length - 1] : ""
          var d = JSON.parse(last)
          // Sanitize any overdriven sink-inputs left by previous broken code
          var streams = d.streams || []
          streams.forEach(function(s) {
            if (s.vol > 100) {
              s.vol = 100
              var ids = s.indices || (s.index !== undefined ? [s.index] : [])
              ids.forEach(function(i) {
                Quickshell.execDetached(["bash", "-c",
                  "pactl set-sink-input-volume " + i + " 100%"])
              })
            }
          })
          root.streams     = streams
          root.masterVol   = (d.master ? d.master.vol : 100) / 100.0
          root.masterMuted = d.master ? d.master.muted : false
        } catch(e) {}
      }
    }
  
    Column {
      id: col
      anchors { left: parent.left; right: parent.right; top: parent.top }
      spacing: 0
  
      // ── Master volume ─────────────────────────────────────────────────────
      Item {
        width: col.width
        height: 38
  
        Row {
          anchors {
            left: parent.left; right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 14; rightMargin: 14
          }
          spacing: 0
  
          Text {
            id: masterLabel
            width: 86
            text: "Master"
            elide: Text.ElideRight
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.foreground
            opacity: root.masterMuted ? 0.25 : 0.9
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }
  
          Item {
            id: masterSliderArea
            width: parent.width - masterLabel.width - masterVolLabel.width - masterMuteBtn.width - 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.masterMuted ? 0.35 : 1.0
  
            Rectangle {
              id: masterTrack
              anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
              height: 3; radius: 2
              color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
  
              Rectangle {
                width: parent.width * Math.min(root.masterVol, 1.0)
                height: parent.height; radius: parent.radius
                color: Theme.accent; opacity: 0.85
              }
            }
  
            Rectangle {
              x: masterTrack.width * Math.min(root.masterVol, 1.0) - width / 2
              anchors.verticalCenter: masterTrack.verticalCenter
              width: 10; height: 10; radius: 5
              color: Theme.accent
              visible: masterMa.containsMouse || masterMa.pressed
            }
  
            Timer {
              id: masterDebounce
              interval: 40
              onTriggered: Quickshell.execDetached(["bash", "-c",
                "pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(root.masterVol * 100) + "%"])
            }
  
            MouseArea {
              id: masterMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              function applyVol(mouseX) {
                root.masterVol = Math.max(0.0, Math.min(1.0, mouseX / masterTrack.width))
                masterDebounce.restart()
              }
              onPressed:         { root.dragging = true }
              onReleased:        { root.dragging = false }
              onClicked:         (mouse) => applyVol(mouse.x)
              onPositionChanged: (mouse) => { if (pressed) applyVol(mouse.x) }
            }
          }
  
          Item { width: 8; height: 1 }
  
          Text {
            id: masterVolLabel
            width: 34
            text: Math.round(root.masterVol * 100) + "%"
            horizontalAlignment: Text.AlignRight
            font.family: Theme.font; font.pixelSize: Theme.fontSize
            color: Theme.foreground
            opacity: root.masterMuted ? 0.25 : 0.5
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
          }
  
          Item { width: 8; height: 1 }
  
          Text {
            id: masterMuteBtn
            text: root.masterMuted ? Glyphs.paMutedX : Glyphs.paDefault[1]
            font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
            color: root.masterMuted ? Theme.activeRed : Theme.foreground
            opacity: root.masterMuted ? 0.9 : (masterMuteHov.containsMouse ? 0.8 : 0.35)
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
            HoverHandler { id: masterMuteHov }
            MouseArea {
              anchors.fill: parent; anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.masterMuted = !root.masterMuted
                Quickshell.execDetached(["bash", "-c",
                  "pactl set-sink-mute @DEFAULT_SINK@ toggle"])
              }
            }
          }
        }
      }
  
      // Separator between master and apps
      Rectangle {
        width: col.width; height: 1
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.08)
      }
  
      Repeater {
        model: root.streams
  
        delegate: Item {
          required property var modelData
  
          // independent per-app vol (0–100%), capped at 100% — no overdriving
          property real localVol: Math.min(modelData.vol / 100.0, 1.0)
          property bool localMuted: modelData.muted
  
          width: col.width
          height: 36
  
          Row {
            anchors {
              left: parent.left; right: parent.right
              verticalCenter: parent.verticalCenter
              leftMargin: 14; rightMargin: 14
            }
            spacing: 0
  
            Text {
              id: nameLabel
              width: 86
              text: modelData.name
              elide: Text.ElideRight
              font.family: Theme.font
              font.pixelSize: Theme.fontSize
              color: Theme.foreground
              opacity: localMuted ? 0.25 : 0.75
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
            }
  
            Item {
              id: sliderArea
              width: parent.width - nameLabel.width - volLabel.width - muteBtn.width - 20
              height: 20
              anchors.verticalCenter: parent.verticalCenter
              opacity: localMuted ? 0.35 : 1.0
  
              Rectangle {
                id: trackBg
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 3; radius: 2
                color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)
  
                Rectangle {
                  width: parent.width * localVol
                  height: parent.height; radius: parent.radius
                  color: Theme.accent; opacity: 0.85
                }
              }
  
              Rectangle {
                x: trackBg.width * Math.min(localVol, 1.0) - width / 2
                anchors.verticalCenter: trackBg.verticalCenter
                width: 10; height: 10; radius: 5
                color: Theme.accent
                visible: sliderMa.containsMouse || sliderMa.pressed
              }
  
              Timer {
                id: appDebounce
                interval: 40
                onTriggered: {
                  var ids = modelData.indices || (modelData.index !== undefined ? [modelData.index] : [])
                  ids.forEach(function(i) {
                    Quickshell.execDetached(["bash", "-c",
                      "pactl set-sink-input-volume " + i + " " + Math.round(localVol * 100) + "%"])
                  })
                }
              }
  
              MouseArea {
                id: sliderMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                function applyVol(mouseX) {
                  localVol = Math.max(0.0, Math.min(1.0, mouseX / trackBg.width))
                  appDebounce.restart()
                }
                onPressed:         { root.dragging = true }
                onReleased:        { root.dragging = false }
                onClicked:         (mouse) => applyVol(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) applyVol(mouse.x) }
              }
            }
  
            Item { width: 8; height: 1 }
  
            Text {
              id: volLabel
              width: 34
              text: Math.round(localVol * 100) + "%"
              horizontalAlignment: Text.AlignRight
              font.family: Theme.font; font.pixelSize: Theme.fontSize
              color: Theme.foreground
              opacity: localMuted ? 0.25 : 0.5
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
            }
  
            Item { width: 8; height: 1 }
  
            Text {
              id: muteBtn
              text: localMuted ? Glyphs.paMutedX : Glyphs.paDefault[1]
              font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
              color: localMuted ? Theme.activeRed : Theme.foreground
              opacity: localMuted ? 0.9 : (muteHov.containsMouse ? 0.8 : 0.35)
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
              HoverHandler { id: muteHov }
              MouseArea {
                anchors.fill: parent; anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  localMuted = !localMuted
                  var ids = modelData.indices || (modelData.index !== undefined ? [modelData.index] : [])
                  ids.forEach(function(i) {
                    Quickshell.execDetached(["bash", "-c",
                      "pactl set-sink-input-mute " + i + " toggle"])
                  })
                }
              }
            }
          }
        }
      }
  
      // Empty state
      Item {
        width: parent.width; height: 30
        visible: root.streams.length === 0
        Text {
          anchors { left: parent.left; leftMargin: 32; verticalCenter: parent.verticalCenter }
          text: "No active apps"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.35
          renderType: Text.NativeRendering
        }
      }
  
      Item { width: parent.width; height: 8 }
    }
  }

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
