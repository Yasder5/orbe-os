// Anneau de focus Orbe : 2 px d'accent et un halo, autour de l'élément parent.
// À placer comme enfant de l'élément mis en avant (un Rectangle), avec visible lié à son état.
// Dessiné sous le parent (z négatif) : le halo et l'anneau ne débordent qu'à l'extérieur.

import QtQuick
import QtQuick.Effects
import qs

Item {
    id: ring

    property real radius: Theme.radiusM

    z: -1
    anchors.fill: parent
    anchors.margins: -2
    opacity: visible ? 1 : 0

    RectangularShadow {
        anchors.fill: parent
        radius: ring.radius + 2
        blur: 32
        spread: 0
        color: Theme.focusGlow
    }

    Rectangle {
        anchors.fill: parent
        radius: ring.radius + 2
        color: Theme.transparent
        border.width: 2
        border.color: Theme.accent
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durFast
        }
    }
}
