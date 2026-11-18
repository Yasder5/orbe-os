// Ligne de réglage : titre et explication à gauche, contrôle à droite (enfant de la ligne).

import QtQuick
import qs

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias control: slot.data

    width: parent ? parent.width : 400
    implicitHeight: Math.max(56, texts.implicitHeight + Theme.space3 * 2)

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.line
    }

    Column {
        id: texts

        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: Theme.space4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        OText {
            width: parent.width
            text: root.title
            elide: Text.ElideRight
        }
        OText {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.muted
            font.pixelSize: Theme.textS
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: slot

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
