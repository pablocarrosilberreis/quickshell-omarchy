import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland


// Omarchy QuickShell bar — top, one panel per monitor.
ShellRoot {
  id: shell

  property bool barVisible: true

  // ── Reusable popup primitives (inline) ─────────────────────────────────
  component PopupFrame: Rectangle {
    id: root
  
    property bool popupVisible: false
    readonly property bool active: _open || _closing
    property bool _open: false
    property bool _closing: false
  
    radius: Theme.windowRadius
    color: Qt.darker(Theme.background, 1.8)
  
    // Hidden resting state; grow from the top edge.
    opacity: 0
    scale: 0.9
    transformOrigin: Item.Top
    property real _slideY: -8
    transform: Translate { y: root._slideY }
  
    // If created while already visible (e.g. a stacked-toast Repeater delegate),
    // play the enter animation so it slides in like the persistent popups.
    Component.onCompleted: if (popupVisible) { _open = true; enterAnim.restart() }
  
    onPopupVisibleChanged: {
      if (popupVisible) {
        _closing = false
        _open = true
        exitAnim.stop()
        enterAnim.restart()
      } else if (_open) {
        _open = false
        _closing = true
        enterAnim.stop()
        exitAnim.restart()
      }
    }
  
    // Open: fade in, slide down, and a soft spring-scale with a small overshoot.
    ParallelAnimation {
      id: enterAnim
      NumberAnimation { target: root; property: "opacity"; from: 0;    to: 1; duration: 160; easing.type: Easing.OutCubic }
      NumberAnimation { target: root; property: "_slideY"; from: -8;   to: 0; duration: 220; easing.type: Easing.OutCubic }
      NumberAnimation {
        target: root; property: "scale"; from: 0.9; to: 1
        duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.1
      }
    }
  
    // Close: quick fade + shrink, then release the window.
    ParallelAnimation {
      id: exitAnim
      NumberAnimation { target: root; property: "opacity"; to: 0;    duration: 130; easing.type: Easing.InCubic }
      NumberAnimation { target: root; property: "_slideY"; to: -6;   duration: 130; easing.type: Easing.InCubic }
      NumberAnimation { target: root; property: "scale";   to: 0.94; duration: 130; easing.type: Easing.InCubic }
      onFinished: root._closing = false
    }
  }
  component PopupPanel: PanelWindow {
    id: root
  
    property bool shown: false
    property real anchorX: 0
    property real anchorW: 0
    property real screenWidth: 0
    property int popupWidth: 300
    property string ns: "quickshell-popup"
    property int popupKeyboardFocus: WlrKeyboardFocus.None
    property real frameRadius: Theme.windowRadius
    property int bottomPadding: 10
    signal dismissed()
  
    // Content is added to the frame (its parent is the frame).
    default property alias content: frame.data
  
    // Keep the window alive until the frame's close animation finishes.
    visible: frame.active
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: -1
    WlrLayershell.namespace: root.ns
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.popupKeyboardFocus
    WlrLayershell.margins.top: Theme.barHeight
  
    // Internal children assigned explicitly so they don't land in the
    // `content` default-property alias above.
    data: [
      MouseArea { anchors.fill: parent; z: 0; onClicked: root.dismissed() },
      PopupFrame {
        id: frame
        popupVisible: root.shown
        z: 1
        x: Math.max(4, Math.min(
          root.anchorX + root.anchorW / 2 - root.popupWidth / 2,
          root.screenWidth - root.popupWidth - 4))
        y: Theme.popupGap
        width: root.popupWidth
        radius: root.frameRadius
        implicitHeight: frame.childrenRect.y + frame.childrenRect.height + root.bottomPadding
      }
    ]
  }


  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData
        screen: modelData

        visible: shell.barVisible
        anchors { top: true; left: true; right: true }
        implicitHeight: Theme.barHeight
        exclusiveZone: shell.barVisible ? Theme.barHeight : 0
        color: "transparent"

        WlrLayershell.namespace: "quickshell-bar"
        WlrLayershell.layer: WlrLayer.Top

        Bar { anchors.fill: parent }
      }
    }
  }

  // ── Media player popup — appears below the player bar item on hover ──────
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData

        visible: mediaPopupContent.active
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.namespace: "quickshell-mediaplayer"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.top: Theme.barHeight

        PopupFrame {
          id: mediaPopupContent
          popupVisible: MediaPlayerState.popupVisible && MediaPlayerState.active
          z: 1
          x: Math.max(4, Math.min(
            MediaPlayerState.anchorX + MediaPlayerState.anchorW / 2 - 190,
            modelData.width - 380 - 4))
          y: Theme.popupGap
          width: 380
          implicitHeight: popupColumn.implicitHeight + 30
          radius: Theme.windowRadius

          HoverHandler {
            onHoveredChanged: hovered ? MediaPlayerState.show() : MediaPlayerState.hide()
          }

          Column {
            id: popupColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 12; topMargin: 15 }
            spacing: 8

            // Album art + title/artist row
            Row {
              spacing: 10
              width: parent.width

              // Album art
              Item {
                width: 72; height: 72
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                  anchors.fill: parent
                  radius: 6
                  color: Theme.foreground
                  opacity: 0.12
                  visible: popArt.status !== Image.Ready
                }
                Text {
                  anchors.centerIn: parent
                  text: "♫"
                  font.family: Theme.font
                  font.pixelSize: 18
                  color: Theme.foreground
                  opacity: 0.35
                  visible: popArt.status !== Image.Ready
                  renderType: Text.NativeRendering
                }
                Image {
                  id: popArt
                  anchors.fill: parent
                  source: MediaPlayerState.artUrl
                  fillMode: Image.PreserveAspectCrop
                  visible: status === Image.Ready
                  layer.enabled: true
                }
                Rectangle {
                  anchors.fill: parent
                  radius: 6
                  color: "transparent"
                  border.color: Qt.lighter(Theme.background, 1.6)
                  border.width: 1
                }
              }

              // Title + artist
              Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                width: parent.width - 82

                Text {
                  text: MediaPlayerState.trackTitle
                  font.family: Theme.font
                  font.pixelSize: Theme.fontSize
                  font.bold: true
                  color: Theme.foreground
                  elide: Text.ElideRight
                  width: parent.width
                  renderType: Text.NativeRendering
                }
                Text {
                  text: MediaPlayerState.artist
                  font.family: Theme.font
                  font.pixelSize: Theme.fontSize - 1
                  color: Theme.foreground
                  opacity: 0.65
                  elide: Text.ElideRight
                  width: parent.width
                  visible: MediaPlayerState.artist.length > 0
                  renderType: Text.NativeRendering
                }
              }
            }

            // Progress bar + time
            Column {
              width: parent.width
              spacing: 4

              // Progress bar
              Rectangle {
                width: parent.width
                height: 3
                radius: 2
                color: Qt.lighter(Theme.background, 1.6)

                Rectangle {
                  width: MediaPlayerState.durationSec > 0
                    ? parent.width * (MediaPlayerState.positionSec / MediaPlayerState.durationSec)
                    : 0
                  height: parent.height
                  radius: 2
                  color: Theme.accent
                }
              }

              // Time
              Item {
                width: parent.width
                height: posLabel.implicitHeight

                Text {
                  id: posLabel
                  anchors.left: parent.left
                  text: MediaPlayerState.fmt(MediaPlayerState.positionSec)
                  font.family: Theme.font
                  font.pixelSize: Theme.fontSize - 2
                  color: Theme.foreground
                  opacity: 0.65
                  renderType: Text.NativeRendering
                }
                Text {
                  id: durLabel
                  anchors.right: parent.right
                  text: MediaPlayerState.fmt(MediaPlayerState.durationSec)
                  font.family: Theme.font
                  font.pixelSize: Theme.fontSize - 2
                  color: Theme.foreground
                  opacity: 0.65
                  renderType: Text.NativeRendering
                }
              }
            }

            // Playback controls
            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 4

              Rectangle {
                width: 36; height: 36; radius: 18
                color: Qt.lighter(Theme.background, 1.4)
                Text {
                  width: parent.width; height: parent.height
                  text: Glyphs.mediaPrev
                  font.family: Theme.font
                  font.pixelSize: 17
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  color: Theme.foreground
                }
                MouseArea { anchors.fill: parent; onClicked: prevProc.running = true }
              }

              Rectangle {
                width: 36; height: 36; radius: 18
                color: Theme.accent
                Text {
                  width: parent.width; height: parent.height
                  text: Glyphs.mediaPlay
                  font.family: Theme.font
                  font.pixelSize: 17
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  color: Theme.background
                  visible: MediaPlayerState.playerStatus !== "Playing"
                }
                Text {
                  width: parent.width; height: parent.height
                  text: Glyphs.mediaPause
                  font.family: Theme.font
                  font.pixelSize: 17
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  color: Theme.background
                  visible: MediaPlayerState.playerStatus === "Playing"
                }
                MouseArea { anchors.fill: parent; onClicked: playPauseProc.running = true }
              }

              Rectangle {
                width: 36; height: 36; radius: 18
                color: Qt.lighter(Theme.background, 1.4)
                Text {
                  width: parent.width; height: parent.height
                  text: Glyphs.mediaNext
                  font.family: Theme.font
                  font.pixelSize: 17
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  color: Theme.foreground
                }
                MouseArea { anchors.fill: parent; onClicked: nextProc.running = true }
              }
            }

          }
        }

          Process { id: prevProc;      command: ["playerctl", "--player=" + MediaPlayerState.playerName, "previous"] }
          Process { id: playPauseProc; command: ["playerctl", "--player=" + MediaPlayerState.playerName, "play-pause"] }
          Process { id: nextProc;      command: ["playerctl", "--player=" + MediaPlayerState.playerName, "next"] }
      }
    }
  }

  // ── Anchored click-to-dismiss popups (kb / wifi / bluetooth / audio / sysinfo) ──
  // All share the same PanelWindow + click-outside + framed-below-widget layout,
  // captured once in PopupPanel.qml.

  // Keyboard layout picker — below the KbLayout widget on click.
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PopupPanel {
        required property var modelData
        screen: modelData
        screenWidth: modelData.width
        shown: KbLayoutState.visible
        ns: "quickshell-kblayout"
        popupKeyboardFocus: WlrKeyboardFocus.OnDemand
        anchorX: KbLayoutState.anchorX
        anchorW: KbLayoutState.anchorW
        bottomPadding: 5
        onDismissed: KbLayoutState.hide()
        Popups.KbLayoutPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
      }
    }
  }

  // WiFi network picker — below the network widget on click.
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PopupPanel {
        required property var modelData
        screen: modelData
        screenWidth: modelData.width
        shown: WifiState.visible
        ns: "quickshell-wifi"
        popupKeyboardFocus: WifiState.pendingNetwork !== null
          ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchorX: WifiState.anchorX
        anchorW: WifiState.anchorW
        bottomPadding: 5
        onDismissed: WifiState.hide()
        Popups.WifiPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
      }
    }
  }

  // Bluetooth device picker — below the BT widget on click.
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PopupPanel {
        required property var modelData
        screen: modelData
        screenWidth: modelData.width
        shown: BluetoothState.visible
        ns: "quickshell-bluetooth"
        anchorX: BluetoothState.anchorX
        anchorW: BluetoothState.anchorW
        onDismissed: BluetoothState.hide()
        Popups.BluetoothPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
      }
    }
  }

  // Audio device picker — below the volume widget on click.
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PopupPanel {
        required property var modelData
        screen: modelData
        screenWidth: modelData.width
        shown: AudioState.visible
        ns: "quickshell-audio"
        popupWidth: 320
        anchorX: AudioState.anchorX
        anchorW: AudioState.anchorW
        bottomPadding: 7
        onDismissed: AudioState.hide()
        Popups.AudioPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 7 } }
      }
    }
  }

  // System resources popup — appears below the CPU/RAM widget on hover.
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData

        visible: sysFrame.active
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.namespace: "quickshell-sysinfo"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.top: Theme.barHeight

        PopupFrame {
          id: sysFrame
          popupVisible: SysInfoState.visible
          z: 1
          x: Math.max(4, Math.min(
            SysInfoState.anchorX + SysInfoState.anchorW / 2 - width / 2,
            modelData.width - width - 4))
          y: Theme.popupGap
          width: 300
          implicitHeight: sysContent.implicitHeight + 10

          Popups.SysInfoPopup {
            id: sysContent
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 }
          }

          HoverHandler {
            onHoveredChanged: hovered ? SysInfoState.show() : SysInfoState.hide()
          }
        }
      }
    }
  }

  // ── Calendar popup — appears below the clock on hover ──────────────────
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData

        visible: calFrame.active
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.namespace: "quickshell-calendar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.top: Theme.barHeight

        MouseArea { anchors.fill: parent; z: 0; onClicked: CalendarState.hide() }

        PopupFrame {
          id: calFrame
          popupVisible: CalendarState.visible
          z: 1
          x: Math.max(4, Math.min(
            CalendarState.anchorX + CalendarState.anchorW / 2 - calFrame.implicitWidth / 2,
            modelData.width - calFrame.implicitWidth - 4))
          y: Theme.popupGap
          implicitWidth: calContent.implicitWidth + 36
          implicitHeight: calContent.implicitHeight + 36
          radius: Theme.windowRadius

          Popups.CalendarPopup {
            id: calContent
            anchors { top: parent.top; topMargin: 18; horizontalCenter: parent.horizontalCenter }
          }

          HoverHandler {
            onHoveredChanged: hovered ? CalendarState.show() : CalendarState.hide()
          }
        }
      }
    }
  }

  // ── Notification toasts — up to 3 stacked at top-center ────────────────
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData

        // Stay mapped while any toast is on screen (incl. its close animation,
        // since expireToast only removes the item once the anim has finished).
        visible: NotifState.visibleToasts.length > 0
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.namespace: "notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.top: Theme.barHeight

        // Only the toast stack captures the mouse; the rest of this full-screen
        // overlay is click-through, so windows behind stay usable.
        mask: Region { item: toastStack }

        Column {
          id: toastStack
          anchors { top: parent.top; topMargin: Theme.popupGap; horizontalCenter: parent.horizontalCenter }
          spacing: 8

          Repeater {
            // ScriptModel diffs by reference, so existing toasts keep their
            // delegate (and their running 3s timer) when the stack shifts.
            model: ScriptModel { values: NotifState.visibleToasts }

            delegate: PopupFrame {
              id: toastFrame
              required property var modelData

              // Each toast owns its lifetime: visible 3s, then it animates out
              // and removes itself from the stack once the anim finishes.
              property bool alive: true
              popupVisible: alive && modelData != null
              onActiveChanged: if (!active) NotifState.expireToast(toastFrame.modelData)

              width: 420
              implicitHeight: toastInner.implicitHeight + 20
              radius: Theme.windowRadius
              // Green frame matching Omarchy's active-window border.
              border.color: Theme.accent
              border.width: 2

              Timer { running: toastFrame.alive; interval: 3000; onTriggered: toastFrame.alive = false }

              Column {
                id: toastInner
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; rightMargin: 32 }
                spacing: 3

                Text {
                  text: NotifState.sourceLabel(toastFrame.modelData)
                  font.family: Theme.font; font.pixelSize: 10
                  color: Theme.foreground; opacity: 0.45
                  renderType: Text.NativeRendering
                }
                Text {
                  width: parent.width
                  wrapMode: Text.Wrap
                  text: NotifState.title(toastFrame.modelData)
                  font.family: Theme.font; font.pixelSize: 13; font.bold: true
                  color: Theme.foreground
                  renderType: Text.NativeRendering
                }
                Text {
                  width: parent.width
                  wrapMode: Text.Wrap
                  visible: text.length > 0
                  text: NotifState.subtitle(toastFrame.modelData)
                  font.family: Theme.font; font.pixelSize: 11
                  color: Theme.foreground; opacity: 0.7
                  renderType: Text.NativeRendering
                }
              }

              // Click body: run default action (or open screenshot), then dismiss.
              MouseArea {
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 32 }
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var t = toastFrame.modelData
                  if (t) {
                    if ((t.summary || "").indexOf("Screenshot") >= 0) {
                      Quickshell.execDetached(["bash", "-c",
                        "f=$(ls -t ~/Pictures/screenshot-*.png 2>/dev/null | head -1); [ -n \"$f\" ] && satty --filename \"$f\" --output-filename \"$f\" --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy"])
                    }
                    var acts = t.actions || []
                    for (var i = 0; i < acts.length; i++) {
                      if (acts[i].identifier === "default") { try { acts[i].invoke() } catch (e) {} break }
                    }
                  }
                  toastFrame.alive = false
                }
              }

              Text {
                anchors { right: parent.right; top: parent.top; margins: 10 }
                text: "✕"
                font.family: Theme.font; font.pixelSize: 12
                color: Theme.foreground; opacity: 0.45
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: toastFrame.alive = false
                }
              }
            }
          }
        }
      }
    }
  }

  // Visibility toggle: `qs ipc call bar toggle` (bound to Super+Shift+Space).
  IpcHandler {
    target: "bar"
    function toggle(): void { shell.barVisible = !shell.barVisible }
    function show(): void { shell.barVisible = true }
    function hide(): void { shell.barVisible = false }
  }
}

