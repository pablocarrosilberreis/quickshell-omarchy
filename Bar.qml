import QtQuick
import Quickshell

// Bar: floating bubble groups on a transparent background.
Item {
  id: bar
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH")
    || (Quickshell.env("HOME") + "/.local/share/omarchy")

  MouseArea {
    anchors.fill: parent
    z: -1
    onClicked: { KbLayoutState.hide(); WifiState.hide(); BluetoothState.hide(); AudioState.hide(); SysInfoState.hide() }
  }

  // ── LEFT ──────────────────────────────────────────────────────────────────
  Row {
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    // Menu + active app
    Bubble {
      OmarchyMenu {}
      ActiveApp {}
    }

    // Workspaces
    Bubble { hpad: 4; Workspaces {} }

    // Media player (hidden when nothing is playing)
    Bubble { MediaPlayer {} }
  }

  // ── CENTER ────────────────────────────────────────────────────────────────
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    // Clock + weather + script indicators
    Bubble {
      Clock {}
      UpdateIndicator {}
      Voxtype {}
      ScriptIndicator {
        scriptPath: bar.omarchyPath + "/default/waybar/indicators/screen-recording.sh"
        clickCmd: "omarchy-capture-screenrecording"
      }
      ScriptIndicator {
        scriptPath: bar.omarchyPath + "/default/waybar/indicators/idle.sh"
        clickCmd: "omarchy-toggle-idle"
      }
      ScriptIndicator {
        scriptPath: bar.omarchyPath + "/default/waybar/indicators/notification-silencing.sh"
        clickCmd: "omarchy-toggle-notification-silencing"
      }
    }
  }

  // ── RIGHT ─────────────────────────────────────────────────────────────────
  Row {
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Bubble { Tray {} }
    Bubble { Volume {} }
    Bubble { KbLayout {} }
    Bubble { Bluetooth {} }
    Bubble { Network {} }
    Bubble { SysInfo {} }
    Bubble { Battery {} }
  }
}
