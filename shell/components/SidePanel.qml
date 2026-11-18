// Panneau qui sort de derrière la barre (lanceur, centre, tableau de bord, réglages rapides) :
// fenêtre transparente plein écran sur l'écran actif, clic à côté pour fermer, Échap aussi.
// Le contenu se place dans « panel » (enfants par défaut).

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs

PanelWindow {
    id: win

    required property var modelData
    property bool open: false
    property string namespace: "orbe-panel"
    property real panelWidth: 420
    property real panelHeight: height - Theme.space3 * 2
    // Aligné en haut (lanceur) ou étiré (centre, tableau de bord).
    property bool keyboard: true
    readonly property bool vertical: Config.barVertical
    property real progress: open ? 1 : 0
    default property alias content: inner.data

    signal closeRequested

    screen: modelData
    visible: open || progress > 0
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.transparent
    WlrLayershell.namespace: namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open && keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on progress {
        NumberAnimation {
            duration: Theme.durMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curve
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Item {
        x: win.vertical ? Theme.barSize : 0
        y: win.vertical ? 0 : Theme.barSize
        width: win.width - x
        height: win.height - y
        clip: true

        Item {
            id: panel

            width: win.panelWidth
            height: Math.min(win.panelHeight, parent.height - Theme.space3 * 2)
            x: Theme.space3 - (win.vertical ? (1 - win.progress) * (width + 60) : 0)
            y: Theme.space3 - (win.vertical ? 0 : (1 - win.progress) * (height + 60))
            opacity: win.progress
            focus: win.open
            Keys.onEscapePressed: win.closeRequested()

            RectangularShadow {
                anchors.fill: background
                offset.y: 18
                blur: 40
                radius: Theme.radiusL
                color: Theme.shadow
            }

            Rectangle {
                id: background

                anchors.fill: parent
                radius: Theme.radiusL
                color: Theme.panel
                border.width: 1
                border.color: Theme.line
            }

            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: inner

                anchors.fill: parent
                anchors.margins: Theme.space4
            }
        }
    }
}
