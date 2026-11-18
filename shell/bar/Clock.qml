// Horloge en JetBrains Mono : heures au-dessus des minutes dans la barre verticale,
// « HH:mm » dans la barre horizontale.

import Quickshell
import QtQuick
import qs
import qs.components

Item {
    id: root

    property bool vertical: true
    readonly property string hours: Qt.formatDateTime(clock.date, Config.clock24h ? "HH" : "hh")
    readonly property string minutes: Qt.formatDateTime(clock.date, "mm")

    implicitWidth: vertical ? Theme.barSize - Theme.space3 : label.implicitWidth + Theme.space3 * 2
    implicitHeight: vertical ? label.implicitHeight + Theme.space2 : Theme.barSize - Theme.space3

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    OText {
        id: label

        anchors.centerIn: parent
        mono: true
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.05
        text: root.vertical ? `${root.hours}\n${root.minutes}` : `${root.hours}:${root.minutes}`
        font.pixelSize: Theme.textM
        font.weight: Font.Medium
    }
}
