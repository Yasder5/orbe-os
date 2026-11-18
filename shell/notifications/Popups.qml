// Bulles de notification empilées en haut à droite, sur l'écran actif.

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            screen: modelData
            visible: Notifs.popups.length > 0 && Panels.isActive(modelData)
            anchors {
                top: true
                right: true
            }
            margins {
                top: Theme.space3
                right: Theme.space3
            }
            implicitWidth: 380 + 60
            implicitHeight: Math.max(1, stack.implicitHeight + 60)
            exclusiveZone: 0
            color: Theme.transparent
            WlrLayershell.namespace: "orbe-notifications"
            WlrLayershell.layer: WlrLayer.Overlay

            // La fenêtre est un peu plus grande que les cartes pour laisser passer l'ombre :
            // seules les cartes reçoivent les clics.
            mask: Region {
                item: stack
            }

            Column {
                id: stack

                x: 40
                spacing: Theme.space2

                Repeater {
                    model: Notifs.popups

                    NotificationCard {
                        required property var modelData

                        notification: modelData
                        popup: true
                    }
                }
            }
        }
    }
}
