// Bouton de panneau : icône et libellé, accent quand l'option est active.

import QtQuick
import qs

Rectangle {
    id: root

    property string icon: "apps"
    property string label: ""
    property bool active: false

    signal clicked

    implicitWidth: row.implicitWidth + Theme.space3 * 2
    implicitHeight: 32
    radius: Theme.radiusS
    color: active ? Theme.accent : mouse.containsMouse ? Theme.line2 : Theme.surface2
    border.width: active ? 0 : 1
    border.color: Theme.line

    Behavior on color {
        ColorAnimation {
            duration: Theme.durFast
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Theme.space2

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            name: root.icon
            color: root.active ? Theme.textOnAccent : Theme.text
        }

        OText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.pixelSize: Theme.textS
            color: root.active ? Theme.textOnAccent : Theme.text
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
