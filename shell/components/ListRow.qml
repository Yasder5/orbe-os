// Ligne de liste cliquable : icône, titre, état. Accent quand elle est choisie.

import QtQuick
import qs

Rectangle {
    id: root

    property string icon: "apps"
    property string title: ""
    property string subtitle: ""
    property bool selected: false

    signal clicked

    implicitHeight: subtitle ? 52 : 40
    radius: Theme.radiusM
    color: mouse.containsMouse ? Theme.surface2 : Theme.transparent
    activeFocusOnTab: true

    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()

    FocusRing {
        visible: root.activeFocus
        radius: Theme.radiusM
    }

    Icon {
        id: glyph

        anchors {
            left: parent.left
            leftMargin: Theme.space3
            verticalCenter: parent.verticalCenter
        }
        width: 18
        height: 18
        name: root.icon
        color: root.selected ? Theme.accent : Theme.muted
    }

    Column {
        anchors {
            left: glyph.right
            right: check.left
            leftMargin: Theme.space3
            rightMargin: Theme.space2
            verticalCenter: parent.verticalCenter
        }

        OText {
            width: parent.width
            text: root.title
            font.pixelSize: Theme.textS
            color: root.selected ? Theme.accent : Theme.text
        }
        OText {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            font.pixelSize: Theme.textXs
            color: Theme.muted
        }
    }

    Icon {
        id: check

        anchors {
            right: parent.right
            rightMargin: Theme.space3
            verticalCenter: parent.verticalCenter
        }
        width: 16
        height: 16
        visible: root.selected
        name: "check"
        color: Theme.accent
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
