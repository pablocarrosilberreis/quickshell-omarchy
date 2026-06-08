import QtQuick

Item {
  id: root

  property string label: ""
  property var devices: []
  property bool isConnectedSection: false
  property bool showRemove: false
  signal activate(string mac)

  implicitHeight: sectionCol.implicitHeight

  Column {
    id: sectionCol
    anchors { left: parent.left; right: parent.right; top: parent.top }
    spacing: 0

    Item {
      width: parent.width; height: 26
      Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        text: root.label
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        color: Theme.foreground
        opacity: 0.7
        renderType: Text.NativeRendering
      }
    }

    Repeater {
      model: root.devices
      delegate: BtDeviceRow {
        required property var modelData
        width: root.width
        deviceName: modelData.name
        deviceMac: modelData.mac
        isConnected: root.isConnectedSection
        removable: root.showRemove
        onActivate: root.activate(deviceMac)
        onRemove: BluetoothState.remove(deviceMac)
      }
    }
  }
}
