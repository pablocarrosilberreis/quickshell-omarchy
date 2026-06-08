pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool visible: false
  property real anchorX: 0
  property real anchorW: 0
  property string currentLayout: "EN"
  // Full human-readable name of the active layout (e.g. "English (US)"),
  // used for the bar bubble's hover tooltip.
  property string currentLayoutName: "English (US)"
  property var allLayouts: []
  property bool layoutsLoaded: false
  property var favoriteCodes: ["us", "es"]

  readonly property var currentLayoutObj: {
    var cur = currentLayout.toLowerCase()
    var code = (cur === "en") ? "us" : cur
    for (var i = 0; i < allLayouts.length; i++) {
      if (allLayouts[i].code === code) return allLayouts[i]
    }
    return { code: code, name: currentLayout }
  }

  readonly property string favFile: Quickshell.env("HOME") + "/.config/quickshell/kb_favorites.json"

  readonly property var favorites: {
    var result = []
    for (var i = 0; i < favoriteCodes.length; i++) {
      var code = favoriteCodes[i]
      var found = null
      for (var j = 0; j < allLayouts.length; j++) {
        if (allLayouts[j].code === code) { found = allLayouts[j]; break }
      }
      if (found) result.push(found)
      else result.push({ code: code, name: code.toUpperCase() })
    }
    return result
  }

  function isFavorite(code) {
    return favoriteCodes.indexOf(code) >= 0
  }

  function toggleFavorite(code, name) {
    var idx = favoriteCodes.indexOf(code)
    var newFavs = favoriteCodes.slice()
    if (idx >= 0) newFavs.splice(idx, 1)
    else newFavs.push(code)
    root.favoriteCodes = newFavs
    saveFavorites()
  }

  function moveFavoriteByCode(code, toIndex) {
    var arr = favoriteCodes.slice()
    var fromIndex = arr.indexOf(code)
    if (fromIndex < 0 || fromIndex === toIndex) return
    arr.splice(fromIndex, 1)
    arr.splice(toIndex, 0, code)
    favoriteCodes = arr
    saveFavorites()
  }

  function saveFavorites() {
    var json = JSON.stringify(root.favoriteCodes)
    Quickshell.execDetached(["bash", "-c",
      "echo '" + json.replace(/'/g, "'\"'\"'") + "' > " + root.favFile])
  }

  function show() {
    WifiState.hide(); BluetoothState.hide(); AudioState.hide(); SysInfoState.hide()
    if (!layoutsLoaded) layoutsPoll.run()
    root.visible = true
  }
  function hide() { root.visible = false }
  function toggle() { root.visible ? hide() : show() }

  function setLayout(code) {
    if (code === "us") root.currentLayout = "EN"
    else root.currentLayout = code.toUpperCase()
    root.currentLayoutName = root.currentLayoutObj.name
    Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/omarchy-set-kb-layout", code])
  }

  // Load favorites from file on startup
  Poll {
    id: favPoll
    immediate: true
    interval: 99999999
    command: ["bash", "-c", "cat " + root.favFile + " 2>/dev/null || echo '[\"us\",\"es\"]'"]
    onUpdated: (out) => {
      try {
        var parsed = JSON.parse(out.trim())
        if (Array.isArray(parsed) && parsed.length > 0)
          root.favoriteCodes = parsed
      } catch (e) {}
    }
  }

  Poll {
    id: layoutPoll
    immediate: true
    interval: 99999999
    command: ["bash", "-c",
      "hyprctl devices -j 2>/dev/null | " +
      "jq -r '([.keyboards[] | select(.name | startswith(\"hl-virtual\") | not)] | first | .active_keymap) // \"English\"'"]
    onUpdated: (out) => {
      var raw = out.trim()
      var k = raw.toLowerCase()
      if (!k) return
      root.currentLayoutName = raw
      if (k.indexOf("spanish") >= 0)        root.currentLayout = "ES"
      else if (k.indexOf("french") >= 0)    root.currentLayout = "FR"
      else if (k.indexOf("german") >= 0)    root.currentLayout = "DE"
      else if (k.indexOf("english") >= 0)   root.currentLayout = "EN"
      else {
        var short = out.trim().substring(0, 2).toUpperCase()
        if (short) root.currentLayout = short
      }
    }
  }

  Poll {
    id: layoutsPoll
    interval: 99999999
    command: ["omarchy-xkb-layouts"]
    onUpdated: (out) => {
      try {
        var parsed = JSON.parse(out)
        if (parsed && parsed.length > 0) {
          root.allLayouts = parsed
          root.layoutsLoaded = true
        }
      } catch (e) {}
    }
  }

}
