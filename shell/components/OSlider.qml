// Curseur Orbe : piste line, remplissage accent, poignée presque carrée.
// Souris (clic, glisser, molette) et clavier (← →, focus Orbe).

import QtQuick
import qs

Item {
    id: root

    property real value: 0
    property real step: 0.05
    property bool enabled: true

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 24
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function set(v) {
        if (enabled)
            moved(Math.max(0, Math.min(1, v)));
    }

    Keys.onLeftPressed: set(value - step)
    Keys.onRightPressed: set(value + step)

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 2
        color: Theme.line

        Rectangle {
            width: Math.max(handle.width / 2, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }

    Rectangle {
        id: handle

        width: 14
        height: 14
        radius: Theme.radiusS
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * Math.max(0, Math.min(1, root.value))
        color: Theme.text
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.set((event.x - 6) / root.width)
        onPositionChanged: event => {
            if (pressed)
                root.set((event.x - 6) / root.width);
        }
        onWheel: event => root.set(root.value + (event.angleDelta.y > 0 ? root.step : -root.step))
    }
}
