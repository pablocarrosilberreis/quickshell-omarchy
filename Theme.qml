pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live theme palette, sourced from the active Omarchy theme's colors.toml.
// Every theme ships one (omarchy generates it from alacritty.toml if missing),
// so the bar recolors for ALL themes — not just ones with a quickshell.json.
//
// `omarchy theme set` swaps the theme dir atomically (rm -rf + mv), which the
// file watcher below can't follow, so the theme-set hook pokes us to reload
// over IPC: `qs ipc call theme reload`.
Singleton {
  id: root

  property color background: "#222222"
  property color foreground: "#c2c2b0"
  property color accent: "#78824b"

  // Indicator "active" red, matching waybar style.css (#a55555).
  readonly property color activeRed: "#a55555"
  // Battery warning tint (<=20%, discharging).
  readonly property color warning: "#cc8844"

  // ── Liquid-glass surfaces ───────────────────────────────────────────────
  // Translucent fills so the Hyprland layer blur shows through as frosted
  // glass, with a bright edge highlight. All derived from the theme palette,
  // so they re-tint on theme change. (Tune `glassAlpha` for more/less frost.)
  readonly property real glassAlpha: 0.80
  readonly property color glass:
    Qt.rgba(background.r, background.g, background.b, glassAlpha)
  // Slightly more opaque for popups (more text over busier blur).
  readonly property color glassStrong:
    Qt.rgba(background.r, background.g, background.b, Math.min(1, glassAlpha + 0.12))
  readonly property color glassBorder:
    Qt.rgba(foreground.r, foreground.g, foreground.b, 0.22)
  // Top specular highlight line, like Apple's glass edge.
  readonly property color glassHighlight:
    Qt.rgba(foreground.r, foreground.g, foreground.b, 0.10)

  readonly property string font: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 12
  readonly property int barHeight: 26

  // Corner rounding for popup/menu frames, kept in sync with Omarchy's
  // Hyprland window rounding (decoration:rounding in ~/.config/hypr/looknfeel.lua).
  readonly property int windowRadius: 8

  // Vertical gap between the bar and popups/toasts anchored below it.
  readonly property int popupGap: 10

  function load(raw) {
    // colors.toml is `key = "#rrggbb"`; pull the semantic ones. Anchored to the
    // line start so `background` doesn't match `selection_background`, etc.
    function val(key) {
      var m = (raw || "").match(
        new RegExp("^[ \\t]*" + key + "[ \\t]*=[ \\t]*\"?(#[0-9a-fA-F]{3,8})", "m"))
      return m ? m[1] : null
    }
    var bg = val("background"), fg = val("foreground"), ac = val("accent")
    if (bg) root.background = bg
    if (fg) root.foreground = fg
    if (ac) root.accent = ac
  }

  function reloadPalette() { colors.reload(); root.load(colors.text()) }

  FileView {
    id: colors
    path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/colors.toml"
    watchChanges: true
    onLoaded: root.load(text())
    onFileChanged: { reload(); root.load(text()) }
  }

  IpcHandler {
    target: "theme"
    function reload(): void { root.reloadPalette() }
  }
}
