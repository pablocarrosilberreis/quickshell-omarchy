import QtQuick
import Quickshell

Item {
  id: row

  property string code: ""
  property string name: ""

  readonly property bool isFav: {
    var codes = KbLayoutState.favoriteCodes
    return codes.indexOf(code) >= 0
  }
  readonly property bool isActive: {
    var cur = KbLayoutState.currentLayout.toLowerCase()
    var c = code.toLowerCase()
    return cur === c || (c === "us" && cur === "en") || (c === "es" && cur === "es")
  }

  height: 30
  width: parent ? parent.width : 280

  HoverHandler { id: rowHover }

  Rectangle {
    anchors.fill: parent
    color: row.isActive
      ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
      : rowHover.hovered
        ? Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
        : "transparent"
  }

  Text {
    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
    text: "▶"
    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
    color: Theme.accent
    visible: row.isActive
    renderType: Text.NativeRendering
  }

  Text {
    anchors {
      left: parent.left; leftMargin: 32
      right: starBtn.left; rightMargin: 4
      verticalCenter: parent.verticalCenter
    }
    text: row.name
    font.family: Theme.font; font.pixelSize: Theme.fontSize
    color: row.isActive ? Theme.accent : Theme.foreground
    opacity: row.isActive ? 1.0 : (ma.containsMouse ? 1.0 : 0.8)
    elide: Text.ElideRight
    renderType: Text.NativeRendering
  }

  Text {
    id: codeLabel
    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
    text: row.code.toUpperCase()
    font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
    color: row.isFav ? Theme.accent : Theme.foreground
    opacity: row.isFav ? 0.7 : 0.35
    renderType: Text.NativeRendering
  }

  // Row click — declared before starBtn so starBtn sits on top
  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: KbLayoutState.setLayout(row.code)
  }

  // Star button — uses rowHover (HoverHandler) to avoid hover-steal bug with ma
  Item {
    id: starBtn
    anchors { right: codeLabel.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
    width: 26; height: 26
    visible: row.isFav || rowHover.hovered

    Text {
      anchors.centerIn: parent
      text: row.isFav ? "★" : "☆"
      font.family: Theme.font; font.pixelSize: Theme.fontSize + 5
      color: row.isFav
        ? (starMa.containsMouse ? "#ffffff" : Theme.accent)
        : (starMa.containsMouse ? "#ffffff" : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.45))
      renderType: Text.NativeRendering
    }

    MouseArea {
      id: starMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: (e) => {
        e.accepted = true
        KbLayoutState.toggleFavorite(row.code, row.name)
      }
    }
  }
}
