pragma Singleton
import QtQuick
import Quickshell

// AUTO-GENERATED from ~/.config/waybar/config.jsonc — byte-exact Nerd Font glyphs.
Singleton {
  // omarchy menu button (uses "omarchy" font, not Nerd Font)
  readonly property string omarchy: ""

  // settings / gear (nf-fa-cog)
  readonly property string settings: ""

  // workspaces
  readonly property string wsActive: "󱓻"

  // network (wifi signal ramp low->high), ethernet, disconnected
  readonly property var netWifi: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
  readonly property string netEthernet: "󰀂"
  readonly property string netDisconnected: "󰤮"

  // bluetooth: on(no conn), off/disabled, connected
  readonly property string btOn: ""
  readonly property string btOff: "󰂲"
  readonly property string btConnected: "󰂱"

  // pulseaudio
  readonly property string paMuted: ""
  readonly property string paMutedX: "󰝟"
  readonly property string paHeadphone: ""
  readonly property string paHeadset: ""
  readonly property var paDefault: ["", "", ""]

  // cpu, update
  readonly property string cpu: "󰍛"
  readonly property string update: ""

  // weather
  readonly property string humidity: "󰖌"

  // voxtype states
  readonly property string voxIdle: ""
  readonly property string voxRecording: "󰍬"
  readonly property string voxTranscribing: "󰔟"

  // media player controls (nf-md-*)
  readonly property string mediaPlay:     "󰐊"
  readonly property string mediaPause:    "󰏤"
  readonly property string mediaPrev:     "󰒮"
  readonly property string mediaNext:     "󰒭"

  // peripherals (nf-md-mouse, nf-md-keyboard) — for per-device battery readout
  readonly property string mouse: "󰍽"
  readonly property string keyboard: "󰌌"
  readonly property string charging: "󰉁"

  // battery
  readonly property string batFull: "󰂅"
  readonly property var batCharging: ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
  readonly property var batDefault: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

  // notification bell / bell-off (nf-md-bell, nf-md-bell_off)
  readonly property string notifBell: "󰂚"
  readonly property string notifBellOff: "󰂛"
}
