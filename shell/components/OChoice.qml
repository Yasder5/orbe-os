// Choix exclusif Orbe (boutons accolés) : model = [{ id, label }], current = id choisi.

import QtQuick
import qs

Row {
    id: root

    property var model: []
    property string current: ""

    signal chosen(string id)

    spacing: Theme.space1

    Repeater {
        model: root.model

        Rectangle {
            id: option

            required property var modelData
            readonly property bool selected: root.current === modelData.id

            width: Math.max(88, label.implicitWidth + Theme.space4 * 2)
            height: 34
            radius: Theme.radiusS
            color: selected ? Theme.accent : mouse.containsMouse ? Theme.line2 : Theme.surface2
            border.width: selected ? 0 : 1
            border.color: Theme.line
            activeFocusOnTab: true

            FocusRing {
                visible: option.activeFocus
                radius: Theme.radiusS
            }

            OText {
                id: label

                anchors.centerIn: parent
                text: option.modelData.label
                color: option.selected ? Theme.textOnAccent : Theme.text
                font.pixelSize: Theme.textS
            }

            Keys.onSpacePressed: root.chosen(option.modelData.id)
            Keys.onReturnPressed: root.chosen(option.modelData.id)

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(option.modelData.id)
            }
        }
    }
}
