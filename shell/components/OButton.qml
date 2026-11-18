// Bouton texte Orbe : plein citron pour l'action principale (accent), discret sinon.

import QtQuick
import qs

Rectangle {
    id: root

    property string text: ""
    property bool accent: false

    signal clicked

    implicitWidth: label.implicitWidth + Theme.space5 * 2
    implicitHeight: 44
    radius: Theme.radiusM
    color: accent ? (mouse.pressed ? Theme.accentActive : mouse.containsMouse ? Theme.accentHover : Theme.accent)
                  : (mouse.containsMouse ? Theme.line2 : Theme.surface2)
    border.width: accent ? 0 : 1
    border.color: Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.durFast
        }
    }

    OText {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.accent ? Theme.textOnAccent : Theme.text
        font.weight: root.accent ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
