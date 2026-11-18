// Batterie, seulement sur un portable : niveau dans l'icône, rouge sous 15 %.

import Quickshell.Services.UPower
import QtQuick
import qs
import qs.components

Item {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property real level: device ? device.percentage : 0
    readonly property bool charging: device && device.state === UPowerDeviceState.Charging
    readonly property bool low: level < 0.15 && !charging

    implicitWidth: Theme.barSize - Theme.space3
    implicitHeight: Theme.barSize - Theme.space3
    visible: device !== null && device.isLaptopBattery

    Icon {
        id: icon

        anchors.centerIn: parent
        name: root.charging ? "battery-charging" : "battery"
        color: root.low ? Theme.danger : Theme.text
    }

    // Remplissage à l'intérieur du contour de l'icône (zone 3..18 x 8..16 sur 24).
    Rectangle {
        visible: !root.charging
        x: icon.x + icon.width * 4.5 / 24
        y: icon.y + icon.height * 9.5 / 24
        width: icon.width * 12 / 24 * Math.max(0, Math.min(1, root.level))
        height: icon.height * 5 / 24
        radius: 1
        color: root.low ? Theme.danger : Theme.accent
    }
}
