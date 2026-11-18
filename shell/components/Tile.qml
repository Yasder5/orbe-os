// Tuile de réglage rapide : icône, titre, état. Accent quand l'option est active.

import QtQuick
import qs

Rectangle {
    id: root

    property string icon: "apps"
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool available: true

    signal clicked

    implicitWidth: 180
    implicitHeight: 64
    radius: Theme.radiusL
    color: active ? Theme.accent : mouse.containsMouse ? Theme.line : Theme.surface2
    border.width: active ? 0 : 1
    border.color: Theme.line
    opacity: available ? 1 : 0.45
    activeFocusOnTab: true

    Keys.onReturnPressed: if (available) clicked()
    Keys.onSpacePressed: if (available) clicked()

    FocusRing {
        visible: root.activeFocus
        radius: Theme.radiusL
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.durFast
        }
    }

    Icon {
        id: glyph

        anchors {
            left: parent.left
            leftMargin: Theme.space4
            verticalCenter: parent.verticalCenter
        }
        name: root.icon
        color: root.active ? Theme.textOnAccent : Theme.text
    }

    Column {
        anchors {
            left: glyph.right
            right: parent.right
            leftMargin: Theme.space3
            rightMargin: Theme.space3
            verticalCenter: parent.verticalCenter
        }

        OText {
            width: parent.width
            text: root.title
            font.weight: Font.DemiBold
            font.pixelSize: Theme.textS
            color: root.active ? Theme.textOnAccent : Theme.text
        }
        OText {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            font.pixelSize: Theme.textXs
            color: root.active ? Theme.textOnAccent : Theme.muted
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.available) root.clicked()
    }
}
