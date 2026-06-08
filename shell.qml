import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Omarchy QuickShell bar — top, one panel per monitor.
ShellRoot {
  id: shell

  property bool barVisible: true

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
          y: 4
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
        KbLayoutPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
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
        WifiPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
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
        BluetoothPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
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
        AudioPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 7 } }
      }
    }
  }

  // System resources popup — below the CPU/RAM widget on click.
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PopupPanel {
        required property var modelData
        screen: modelData
        screenWidth: modelData.width
        shown: SysInfoState.visible
        ns: "quickshell-sysinfo"
        anchorX: SysInfoState.anchorX
        anchorW: SysInfoState.anchorW
        onDismissed: SysInfoState.hide()
        SysInfoPopup { anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 5 } }
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
          y: 4
          implicitWidth: calContent.implicitWidth + 36
          implicitHeight: calContent.implicitHeight + 36
          radius: Theme.windowRadius

          CalendarPopup {
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

  // ── Notification toasts — top-center, slide from bar ───────────────────
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData

        visible: toastRect.active
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: -1

        WlrLayershell.namespace: "notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.margins.top: Theme.barHeight

        property var toast: NotifState.activeToast

        onToastChanged: {
          if (toast !== null)
            toastTimer.restart()
          else
            toastTimer.stop()
        }

        // Every toast shows for a few seconds, then auto-dismisses off-screen.
        // popToast only drops it from the on-screen queue — it stays in the
        // notification center until the user clears it. Applies to all
        // urgencies (incl. Critical), so nothing gets stuck on screen.
        Timer {
          id: toastTimer
          interval: 5000
          onTriggered: NotifState.popToast()
        }

        PopupFrame {
          id: toastRect
          popupVisible: NotifState.activeToast !== null
          z: 1
          x: Math.round((modelData.width - 420) / 2)
          y: 4
          width: 420
          implicitHeight: toastInner.implicitHeight + 20
          radius: Theme.windowRadius
          // Green frame matching Omarchy's active-window border (col.active_border).
          border.color: Theme.accent
          border.width: 2

          Column {
            id: toastInner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; rightMargin: 32 }
            spacing: 3

            Text {
              text: NotifState.sourceLabel(NotifState.activeToast)
              font.family: Theme.font; font.pixelSize: 10
              color: Theme.foreground; opacity: 0.45
              renderType: Text.NativeRendering
            }
            Text {
              width: parent.width
              wrapMode: Text.Wrap
              text: NotifState.activeToast ? NotifState.activeToast.summary : ""
              font.family: Theme.font; font.pixelSize: 13; font.bold: true
              color: Theme.foreground
              renderType: Text.NativeRendering
            }
            Text {
              width: parent.width
              wrapMode: Text.Wrap
              visible: NotifState.activeToast ? NotifState.activeToast.body.length > 0 : false
              text: NotifState.activeToast ? NotifState.activeToast.body : ""
              font.family: Theme.font; font.pixelSize: 11
              color: Theme.foreground; opacity: 0.7
              renderType: Text.NativeRendering
            }
          }

          // Click body to open screenshot in editor (or dismiss)
          MouseArea {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; rightMargin: 32 }
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var t = NotifState.activeToast
              if (!t) { NotifState.dismissToast(); return }
              if (t.summary.indexOf("Screenshot") >= 0) {
                Quickshell.execDetached(["bash", "-c",
                  "f=$(ls -t ~/Pictures/screenshot-*.png 2>/dev/null | head -1); [ -n \"$f\" ] && satty --filename \"$f\" --output-filename \"$f\" --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy"])
              }
              var acts = t.actions || []
              for (var i = 0; i < acts.length; i++) {
                if (acts[i].identifier === "default") { acts[i].invoke(); break }
              }
              NotifState.dismissToast()
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
              onClicked: NotifState.dismissToast()
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
