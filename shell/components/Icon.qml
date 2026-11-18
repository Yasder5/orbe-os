// Icône monoligne Orbe (tracés dans Icons.qml), en trait arrondi.

import QtQuick
import QtQuick.Shapes
import qs

Item {
    id: root

    property string name: "apps"
    property color color: Theme.text
    property real stroke: 1.6

    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: Math.min(root.width, root.height) / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: Theme.transparent
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: Icons.path(root.name)
            }
        }
    }
}
