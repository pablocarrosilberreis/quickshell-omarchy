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

  NotificationServer {
    keepOnReload: true
    bodyMarkupSupported: false

    onNotification: (notif) => {
      notif.tracked = true
      notif.receivedAt = Qt.formatTime(new Date(), "HH:mm")
      // Defer the array reassignments out of the DBus signal callback. They
      // re-evaluate the `model:` binding of NotifCenter's Repeater, which
      // regenerates its delegates; doing that re-entrantly during DBus signal
      // delivery (e.g. while tray/SNI items churn) crashes Qt's QML incubator
      // (segfault in QQuickRepeater::regenerate). Same reason dismiss()/clearAll
      // already use Qt.callLater.
      Qt.callLater(function() {
        root.notifications = [notif].concat(root.notifications.slice(0, 99))
        if (!root.muted)
          root.toastQueue = root.toastQueue.concat([notif])
      })
    }
  }

  // Called by toast timer when a toast auto-expires (keeps in history).
  function popToast() {
    if (toastQueue.length > 0)
      toastQueue = toastQueue.slice(1)
  }

  // Called when user closes the toast manually (keeps in history).
  function dismissToast() {
    if (toastQueue.length > 0)
      toastQueue = toastQueue.slice(1)
  }

  // Remove a notification from history entirely.
  function dismiss(notif) {
    try { notif.dismiss() } catch(e) {}
    // Defer model update so the Repeater delegate isn't destroyed mid-click.
    Qt.callLater(function() {
      notifications = notifications.filter(n => n !== notif)
      toastQueue = toastQueue.filter(n => n !== notif)
    })
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

  function clearAll() {
    var all = notifications.slice()
    for (var n of all) {
      try { n.dismiss() } catch(e) {}
    }
    Qt.callLater(function() {
      notifications = []
      toastQueue = []
    })
  }
}
