// Espaces de travail : actif en accent, occupés en text, vides en line.

import Quickshell.Hyprland
import QtQuick
import qs

Column {
    id: root

    // Toujours au moins 5 cases, davantage si un espace plus loin est utilisé.
    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.map(w => w.id))

    spacing: 6

    Repeater {
        model: root.count

        Rectangle {
            id: cell

            required property int index
            readonly property int wsId: index + 1
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            readonly property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
            readonly property bool isOccupied: workspace !== null && workspace.toplevels.values.length > 0

            anchors.horizontalCenter: parent.horizontalCenter
            width: 6
            height: isActive ? 20 : 6
            radius: 1
            color: isActive ? Theme.accent : isOccupied ? Theme.text : Theme.line

            Behavior on height {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.durFast
                }
            }
        }
    }
}
