// Interrupteur Orbe : piste citron quand il est actif. Espace ou Entrée l'inversent au clavier.

import QtQuick
import qs

Rectangle {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 24
    radius: height / 2
    color: checked ? Theme.accent : Theme.line2
    activeFocusOnTab: true

    Behavior on color {
        ColorAnimation {
            duration: Theme.durFast
        }
    }

    Rectangle {
        width: 18
        height: 18
        radius: 9
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.textOnAccent : Theme.text

        Behavior on x {
            NumberAnimation {
                duration: Theme.durFast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.curve
            }
        }
    }

    FocusRing {
        visible: root.activeFocus
        radius: root.radius
    }

    Keys.onSpacePressed: root.toggled(!root.checked)
    Keys.onReturnPressed: root.toggled(!root.checked)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
