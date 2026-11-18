// Horloge verticale : heures au-dessus des minutes, en JetBrains Mono.

import Quickshell
import QtQuick
import qs

Column {
    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Repeater {
        model: [Qt.formatDateTime(clock.date, "HH"), Qt.formatDateTime(clock.date, "mm")]

        Text {
            required property string modelData

            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: 15
            font.weight: Font.Medium
        }
    }
}
