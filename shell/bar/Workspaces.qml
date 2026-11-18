// Espaces de travail : actif en accent, occupés en text, vides en line.
// Clic : y aller. Molette : suivant ou précédent.

import Quickshell.Hyprland
import QtQuick
import qs

Item {
    id: root

    property bool vertical: true
    // Toujours au moins 5 cases, davantage si un espace plus loin est utilisé.
    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.map(w => w.id))
    readonly property int cell: 6
    readonly property int activeLength: 20

    implicitWidth: vertical ? Theme.barSize - Theme.space3 : grid.implicitWidth + Theme.space3 * 2
    implicitHeight: vertical ? grid.implicitHeight + Theme.space3 * 2 : Theme.barSize - Theme.space3

    function go(target) {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${JSON.stringify(target)} })` : `workspace ${target}`);
    }

    MouseArea {
        anchors.fill: parent
        onWheel: event => root.go(event.angleDelta.y > 0 ? "e-1" : "e+1")
    }

    Grid {
        id: grid

        anchors.centerIn: parent
        columns: root.vertical ? 1 : root.count
        rows: root.vertical ? root.count : 1
        spacing: 6
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: root.count

            Rectangle {
                id: cell

                required property int index
                readonly property int wsId: index + 1
                readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
                readonly property bool isOccupied: workspace !== null && workspace.toplevels.values.length > 0
                readonly property int length: isActive ? root.activeLength : hover.containsMouse ? 10 : root.cell

                width: root.vertical ? root.cell : length
                height: root.vertical ? length : root.cell
                radius: 1
                color: isActive ? Theme.accent : isOccupied ? Theme.text : hover.containsMouse ? Theme.muted : Theme.line2

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durMed
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.curve
                    }
                }
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

                // Zone de clic plus large que le trait.
                MouseArea {
                    id: hover

                    anchors.centerIn: parent
                    width: root.vertical ? Theme.barSize - Theme.space3 : parent.width + 6
                    height: root.vertical ? parent.height + 6 : Theme.barSize - Theme.space3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(cell.wsId)
                }
            }
        }
    }
}
