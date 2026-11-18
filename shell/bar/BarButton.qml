// Bouton carré de la barre : icône monoligne, fond au survol, accent quand il est actif.

import QtQuick
import qs
import qs.components

Item {
    id: root

    property string icon: "apps"
    property bool active: false
    property bool danger: false
    property color iconColor: active ? Theme.accent : hovered && danger ? Theme.danger : Theme.text
    readonly property bool hovered: mouse.containsMouse

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: Theme.barSize - Theme.space3
    implicitHeight: Theme.barSize - Theme.space3

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusM
        color: root.hovered || root.active ? Theme.surface2 : Theme.transparent

        Behavior on color {
            ColorAnimation {
                duration: Theme.durFast
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.iconColor
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => root.clicked(event)
        onWheel: event => root.wheel(event)
    }
}
