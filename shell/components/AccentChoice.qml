// Choix de la couleur d'accent (Theme.accents) : une pastille par couleur, la choisie entourée.
// S'applique tout de suite (Config.accent).

import QtQuick
import qs

Row {
    id: root

    spacing: Theme.space2

    Repeater {
        model: Theme.accents

        Rectangle {
            id: swatch

            required property var modelData
            readonly property bool selected: Theme.accentId === modelData.id

            width: 34
            height: 34
            radius: Theme.radiusM
            color: Theme.transparent
            border.width: selected ? 2 : 1
            border.color: selected ? modelData.accent : mouse.containsMouse ? Theme.line2 : Theme.line
            activeFocusOnTab: true
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData.label
            Accessible.checked: selected

            FocusRing {
                visible: swatch.activeFocus
                radius: Theme.radiusM
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: Theme.radiusS
                color: swatch.modelData.accent
            }

            Keys.onSpacePressed: Config.accent = modelData.id
            Keys.onReturnPressed: Config.accent = modelData.id

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.accent = swatch.modelData.id
            }
        }
    }
}
