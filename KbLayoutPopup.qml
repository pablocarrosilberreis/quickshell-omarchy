import QtQuick
import Quickshell
import QtQuick.Controls

Item {

  // ── inline sub-components ──────────────────────────────────────────────
  component KbLayoutRow: Item {
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

  id: root

  implicitWidth: col.implicitWidth
  implicitHeight: col.implicitHeight

  property string searchText: searchInput.text

  readonly property var filteredLayouts: {
    var q = searchText.toLowerCase().trim()
    if (q === "") return KbLayoutState.allLayouts
    return KbLayoutState.allLayouts.filter(function(l) {
      return l.name.toLowerCase().indexOf(q) >= 0 || l.code.toLowerCase().indexOf(q) >= 0
    })
  }

  Column {
    id: col
    anchors { left: parent.left; right: parent.right; top: parent.top }
    spacing: 0

    // ── Header ───────────────────────────────────────────────────────────────
    Item {
      width: parent.width; height: 42
      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: "KEYBOARD LAYOUT"
        font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground; opacity: 0.7
        renderType: Text.NativeRendering
      }
    }

    // ── Search box ───────────────────────────────────────────────────────────
    Item {
      width: parent.width; height: 36

      Rectangle {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 0; bottomMargin: 6 }
        radius: 8
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.08)
        border.width: 1
        border.color: searchInput.activeFocus
          ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5)
          : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)

        Text {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          text: "Search…"
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground; opacity: 0.3
          renderType: Text.NativeRendering
          visible: searchInput.text === ""
        }

        TextInput {
          id: searchInput
          anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
          font.family: Theme.font; font.pixelSize: Theme.fontSize
          color: Theme.foreground
          selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)
          selectByMouse: true
          clip: true
          MouseArea {
            anchors.fill: parent
            onClicked: parent.forceActiveFocus()
          }
        }
      }
    }


    // ── Favorites section (only when not searching) ───────────────────────────
    Item {
      width: parent.width; height: 26
      visible: searchText === ""
      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: "FAVORITES"
        font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground; opacity: 0.7
        renderType: Text.NativeRendering
      }
    }

    // Favorites with drag-to-reorder (live reorder, items shift during drag)
    Item {
      id: favDragContainer
      width: col.width
      height: KbLayoutState.favorites.length * 30
      visible: searchText === ""

      property string draggingCode: ""
      property int dragFromIndex: -1
      property int dragToIndex: -1
      property real dragY: 0
      property bool dragActive: false

      Repeater {
        model: KbLayoutState.favorites

        delegate: Item {
          id: favWrapper
          required property int index
          required property var modelData
          width: favDragContainer.width
          height: 30

          readonly property bool isBeingDragged: modelData.code === favDragContainer.draggingCode

          y: {
            var from = favDragContainer.dragFromIndex
            var to   = favDragContainer.dragToIndex
            if (from < 0) return index * 30
            if (isBeingDragged) return Math.max(0, Math.min((KbLayoutState.favorites.length - 1) * 30, favDragContainer.dragY))
            if (from < to && index > from && index <= to) return index * 30 - 30
            if (from > to && index >= to && index < from) return index * 30 + 30
            return index * 30
          }

          Behavior on y {
            enabled: favDragContainer.dragActive && !favWrapper.isBeingDragged
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
          }

          opacity: isBeingDragged ? 0.5 : 1.0
          z: isBeingDragged ? 10 : 0

          Item {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 22; height: parent.height

            Text {
              anchors.centerIn: parent
              text: "⠿"
              font.family: Theme.font; font.pixelSize: Theme.fontSize
              color: Theme.foreground
              opacity: gripMa.containsMouse ? 0.65 : 0.22
              renderType: Text.NativeRendering
            }

            MouseArea {
              id: gripMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.SizeVerCursor

              property real dragOffsetY: 0

              onPressed: (mouse) => {
                var p = favWrapper.mapToItem(favDragContainer, 0, 0)
                var pressInContainer = mapToItem(favDragContainer, mouse.x, mouse.y)
                dragOffsetY = pressInContainer.y - p.y
                favDragContainer.dragY = p.y
                favDragContainer.dragFromIndex = favWrapper.index
                favDragContainer.dragToIndex = favWrapper.index
                favDragContainer.draggingCode = favWrapper.modelData.code
                favDragContainer.dragActive = true
              }
              onPositionChanged: (mouse) => {
                if (!pressed || favDragContainer.draggingCode === "") return
                var pos = mapToItem(favDragContainer, mouse.x, mouse.y)
                var maxY = (KbLayoutState.favorites.length - 1) * 30
                favDragContainer.dragY = Math.max(0, Math.min(maxY, pos.y - dragOffsetY))
                favDragContainer.dragToIndex = Math.max(0, Math.min(KbLayoutState.favorites.length - 1, Math.round(favDragContainer.dragY / 30)))
              }
              onReleased: {
                if (favDragContainer.draggingCode === "") return
                var code = favDragContainer.draggingCode
                var toIdx = favDragContainer.dragToIndex
                favDragContainer.dragActive = false
                favDragContainer.draggingCode = ""
                favDragContainer.dragFromIndex = -1
                favDragContainer.dragToIndex = -1
                KbLayoutState.moveFavoriteByCode(code, toIdx)
              }
            }
          }

          KbLayoutRow {
            x: 22
            width: parent.width - 22
            height: parent.height
            code: favWrapper.modelData.code
            name: favWrapper.modelData.name
          }
        }
      }
    }

    // ── Divider ───────────────────────────────────────────────────────────────
    Rectangle {
      width: parent.width; height: 1
      color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.1)
      visible: searchText === "" && KbLayoutState.layoutsLoaded
    }

    // ── All layouts header ────────────────────────────────────────────────────
    Item {
      width: parent.width; height: 26
      visible: KbLayoutState.layoutsLoaded
      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: searchText === "" ? "ALL LAYOUTS" : "RESULTS"
        font.family: Theme.font; font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground; opacity: 0.7
        renderType: Text.NativeRendering
      }
    }

    // Loading indicator
    Item {
      width: parent.width; height: 36
      visible: !KbLayoutState.layoutsLoaded
      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: "Loading layouts…"
        font.family: Theme.font; font.pixelSize: Theme.fontSize
        color: Theme.foreground; opacity: 0.7
        renderType: Text.NativeRendering
      }
    }

    // Scrollable list
    Item {
      width: parent.width
      height: listView.contentHeight < 200 ? listView.contentHeight : 200
      visible: KbLayoutState.layoutsLoaded
      clip: true

      ListView {
        id: listView
        anchors.fill: parent
        model: root.filteredLayouts
        spacing: 0
        clip: true

        delegate: KbLayoutRow {
          required property var modelData
          width: listView.width
          code: modelData.code
          name: modelData.name
        }

        ScrollBar.vertical: ScrollBar {
          policy: ScrollBar.AsNeeded
        }
      }
    }

    Item { width: parent.width; height: 8 }
  }

  onVisibleChanged: {
    if (visible) searchInput.forceActiveFocus()
    else searchInput.text = ""
  }
}
