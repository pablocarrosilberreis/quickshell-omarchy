pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Manages incoming notifications: toast queue + persistent history.
Singleton {
  id: root

  // All received notifications, newest first (kept even after auto-expiry).
  property var notifications: []
  // Queue of notifications to show as toasts. First item is active.
  property var toastQueue: []
  readonly property var activeToast: toastQueue.length > 0 ? toastQueue[0] : null

  // Do-not-disturb: when true, toasts are suppressed (history still recorded).
  property bool muted: false
  function toggleMute() { root.muted = !root.muted }

  // Hard caps so a notification storm can never grow the models unbounded.
  readonly property int maxHistory: 100
  readonly property int maxToasts: 20

  // Drop any entries whose underlying Notification QObject was destroyed
  // (QML turns those references into null) — keeps dangling items out of the
  // models that feed the Repeater/toast delegates.
  function _live(list) { return list.filter(function(n) { return n != null }) }

  NotificationServer {
    keepOnReload: true
    bodyMarkupSupported: false

    onNotification: (notif) => {
      if (!notif) return
      try {
        notif.tracked = true
        notif.receivedAt = Qt.formatTime(new Date(), "HH:mm")
      } catch (e) { return }
      // Defer the array reassignments out of the DBus signal callback (keeps
      // model mutation off the re-entrant DBus delivery path, and batches).
      // NOTE: the actual crash fix is NotifCenter binding its Repeater via
      // Quickshell.ScriptModel — reassigning a plain JS array forced a full
      // QQuickRepeater::regenerate() that segfaulted Qt's QML incubator.
      Qt.callLater(function() {
        if (!notif) return  // destroyed before we got here
        root.notifications = [notif].concat(root._live(root.notifications)).slice(0, root.maxHistory)
        if (!root.muted)
          root.toastQueue = root._live(root.toastQueue).concat([notif]).slice(-root.maxToasts)
      })
    }
  }

  // Called by toast timer when a toast auto-expires (keeps in history).
  function popToast() {
    if (toastQueue.length > 0)
      toastQueue = _live(toastQueue.slice(1))
  }

  // Called when user closes the toast manually (keeps in history).
  function dismissToast() {
    if (toastQueue.length > 0)
      toastQueue = _live(toastQueue.slice(1))
  }

  // Remove a notification from history entirely. Order matters: drop the
  // reference from the models FIRST (so the Repeater/toast destroy their
  // delegate), THEN destroy the QObject on the next tick — dismissing first
  // would leave a delegate bound to a freed Notification and segfault.
  function dismiss(notif) {
    if (!notif) return
    notifications = notifications.filter(function(n) { return n != null && n !== notif })
    toastQueue    = toastQueue.filter(function(n) { return n != null && n !== notif })
    Qt.callLater(function() { try { notif.dismiss() } catch (e) {} })
  }

  // Returns a human-readable source name for a notification.
  function sourceLabel(notif) {
    if (!notif) return ""
    var name = notif.appName || ""
    if (name === "ZapZap") return "WhatsApp"
    if (name && name !== "notify-send") return name
    var icon = notif.appIcon || ""
    if (icon.indexOf("bluetooth") >= 0)            return "Bluetooth"
    if (icon.indexOf("battery") >= 0)              return "Batería"
    if (icon.indexOf("network") >= 0
        || icon.indexOf("wifi") >= 0)              return "Red"
    if (icon.indexOf("volume") >= 0
        || icon.indexOf("audio") >= 0
        || icon.indexOf("sound") >= 0)             return "Audio"
    if (icon.indexOf("camera") >= 0
        || icon.indexOf("screenshot") >= 0)        return "Captura"
    return "Sistema"
  }

  // Clear everything. Empty the models first, then destroy the QObjects on the
  // next tick (same dangling-reference reason as dismiss()).
  function clearAll() {
    var all = _live(notifications)
    notifications = []
    toastQueue = []
    Qt.callLater(function() {
      for (var i = 0; i < all.length; i++) {
        try { if (all[i]) all[i].dismiss() } catch (e) {}
      }
    })
  }
}
