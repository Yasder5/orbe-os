// Barre verticale à gauche, une par écran.

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.components

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            screen: modelData
            anchors {
                left: true
                top: true
                bottom: true
            }
            implicitWidth: Theme.barWidth
            exclusiveZone: Theme.barWidth
            color: Theme.transparent
            WlrLayershell.namespace: "orbe-bar"

            Rectangle {
                anchors.fill: parent
                color: Theme.surface

                // Bordure côté bureau
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                    }
                    width: 1
                    color: Theme.line
                }
            }

            Column {
                anchors {
                    top: parent.top
                    topMargin: Theme.gap
                    horizontalCenter: parent.horizontalCenter
                }
                spacing: Theme.gap + 6

                OrbeLogo {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 30
                    height: 30
                }

                Workspaces {
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Clock {
                anchors {
                    bottom: parent.bottom
                    bottomMargin: Theme.gap
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
