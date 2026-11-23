// Confirmation avant le mode jeu quand des fenêtres sont ouvertes : elles vont être fermées
// (hyprshutdown laisse chaque application proposer d'enregistrer). Entrée confirme, Échap annule.

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.components
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: Panels.gameConfirmOpen && Panels.isActive(modelData)
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
            WlrLayershell.namespace: "orbe-game-confirm"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            onOpenChanged: if (open) content.forceActiveFocus()

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
                onClicked: Panels.gameConfirmOpen = false
            }

            Item {
                id: content

                anchors.fill: parent
                opacity: win.progress
                focus: win.open
                Keys.onEscapePressed: Panels.gameConfirmOpen = false
                Keys.onReturnPressed: Session.game(true)
                Keys.onEnterPressed: Session.game(true)

                Rectangle {
                    anchors.centerIn: parent
                    width: 520
                    height: column.implicitHeight + Theme.space5 * 2
                    radius: Theme.radiusL
                    color: Theme.panel
                    border.width: 1
                    border.color: Theme.line
                    scale: 0.97 + 0.03 * win.progress

                    MouseArea {
                        anchors.fill: parent
                    }

                    Column {
                        id: column

                        anchors.fill: parent
                        anchors.margins: Theme.space5
                        spacing: Theme.space3

                        Icon {
                            width: 32
                            height: 32
                            name: "gamepad"
                            color: Theme.accent
                        }
                        OText {
                            text: "Passer en mode jeu ?"
                            font.pixelSize: Theme.textXl
                            font.weight: Font.DemiBold
                        }
                        OText {
                            width: parent.width
                            text: Session.openWindows === 1
                                ? "La fenêtre ouverte va être fermée. Si elle a du travail non enregistré, elle te le proposera."
                                : `Les ${Session.openWindows} fenêtres ouvertes vont être fermées. Celles qui ont du travail non enregistré te le proposeront.`
                            color: Theme.muted
                            wrapMode: Text.WordWrap
                        }
                        Item {
                            width: 1
                            height: Theme.space2
                        }
                        Row {
                            anchors.right: parent.right
                            spacing: Theme.space2

                            OButton {
                                text: "Annuler"
                                onClicked: Panels.gameConfirmOpen = false
                            }
                            OButton {
                                text: "Mode jeu"
                                accent: true
                                onClicked: Session.game(true)
                            }
                        }
                    }
                }
            }
        }
    }
}
