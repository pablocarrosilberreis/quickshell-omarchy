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

  // Up to this many toasts are shown stacked on screen at once; the rest queue.
  readonly property int maxVisibleToasts: 3
  readonly property var visibleToasts: _live(toastQueue).slice(0, maxVisibleToasts)

  // Drop one specific notification from the on-screen toast stack (it stays in
  // the history). Deferred so a toast delegate is never destroyed mid-callback.
  function expireToast(notif) {
    Qt.callLater(function() {
      root.toastQueue = root._live(root.toastQueue).filter(function(n) { return n !== notif })
    })
  }

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

  // Clear the whole on-screen toast stack at once (they stay in the history) —
  // e.g. when the notification center is opened.
  function clearToasts() { toastQueue = [] }

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
  // Display title for a notification, robust against empty fields: prefer the
  // summary, fall back to the body, then the app name, then a generic label —
  // so a content-less notification never renders as an empty box.
  function title(n) {
    if (!n) return ""
    if (n.summary && n.summary.length) return n.summary
    if (n.body && n.body.length) return n.body
    if (n.appName && n.appName.length && n.appName !== "notify-send") return n.appName
    return "Notificación"
  }

  // Secondary line: the body, shown only when the summary was used as the title
  // (otherwise the body was already promoted to the title, or there is none).
  function subtitle(n) {
    if (!n || !n.summary || !n.summary.length) return ""
    return n.body || ""
  }

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
