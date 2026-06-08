pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live theme palette, sourced from the active Omarchy theme's quickshell.json
// (primary/background/backgroundText). Hot-reloads on `omarchy theme set`.
Singleton {
  id: root

  property color background: "#222222"
  property color foreground: "#c2c2b0"
  property color accent: "#78824b"

  // Indicator "active" red, matching waybar style.css (#a55555).
  readonly property color activeRed: "#a55555"
  // Battery warning tint (<=20%, discharging).
  readonly property color warning: "#cc8844"

  readonly property string font: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 12
  readonly property int barHeight: 26

  // Corner rounding for popup/menu frames, kept in sync with Omarchy's
  // Hyprland window rounding (decoration:rounding in ~/.config/hypr/looknfeel.lua).
  readonly property int windowRadius: 8

  function load(raw) {
    try {
      var c = JSON.parse(raw || "{}")
      if (c.background) root.background = c.background
      if (c.backgroundText) root.foreground = c.backgroundText
      if (c.primary) root.accent = c.primary
    } catch (e) {}
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/quickshell.json"
    watchChanges: true
    onLoaded: root.load(text())
    onFileChanged: { reload(); root.load(text()) }
  }
}
