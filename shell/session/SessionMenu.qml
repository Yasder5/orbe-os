// Menu de session plein écran : fond assombri, orbe au centre, cinq actions.
// Clavier : ← → (ou Tab) pour choisir, Entrée pour valider, Échap pour annuler.

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.components
import qs.services

Scope {
    id: root

    property int current: 0

    Connections {
        target: Panels
        function onSessionOpenChanged() {
            if (Panels.sessionOpen)
                root.current = 0;
        }
    }

    function run(index) {
        Panels.sessionOpen = false;
        Session.run(Session.actions[index].id);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: Panels.sessionOpen && Panels.isActive(modelData)
            property real progress: open ? 1 : 0

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
            WlrLayershell.namespace: "orbe-session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Behavior on progress {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: win.progress
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Panels.sessionOpen = false
            }

            Item {
                id: content

                anchors.fill: parent
                opacity: win.progress
                scale: 0.96 + 0.04 * win.progress
                focus: win.open

                Keys.onPressed: event => {
                    const count = Session.actions.length;
                    if (event.key === Qt.Key_Escape)
                        Panels.sessionOpen = false;
                    else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                        root.current = (root.current + 1) % count;
                    else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                        root.current = (root.current + count - 1) % count;
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                        root.run(root.current);
                    else
                        return;
                    event.accepted = true;
                }

                Orb {
                    id: orb

                    width: Math.min(parent.width, parent.height) * 0.42
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.44 - height / 2
                    visible: win.visible
                }

                Row {
                    id: buttons

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: orb.bottom
                        topMargin: Theme.space6
                    }
                    spacing: Theme.space4

                    Repeater {
                        model: Session.actions

                        Rectangle {
                            id: button

                            required property var modelData
                            required property int index
                            readonly property bool selected: root.current === index
                            readonly property color tint: modelData.danger ? Theme.danger : selected ? Theme.accent : Theme.text

                            width: 112
                            height: 104
                            radius: Theme.radiusL
                            color: selected ? Theme.surface2 : Theme.surface
                            border.width: 1
                            border.color: Theme.line

                            FocusRing {
                                visible: button.selected
                                radius: Theme.radiusL
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.space3

                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 28
                                    height: 28
                                    name: button.modelData.icon
                                    color: button.tint
                                }
                                OText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: button.modelData.label
                                    font.pixelSize: Theme.textS
                                    color: button.modelData.danger ? Theme.danger : Theme.text
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.current = button.index
                                onClicked: root.run(button.index)
                            }
                        }
                    }
                }

                OText {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: buttons.bottom
                        topMargin: Theme.space5
                    }
                    mono: true
                    font.pixelSize: Theme.textXs
                    color: Theme.muted
                    text: "← → choisir  ·  Entrée valider  ·  Échap annuler"
                }
            }
        }
    }
}
