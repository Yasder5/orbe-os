// Barre Orbe, une par écran : verticale à gauche par défaut, horizontale en haut si
// Config.barPosition vaut "top" (réglage rechargé à chaud).
// Début : logo (lanceur), espaces de travail, fenêtre active.
// Fin : zone de notifications système, son, batterie, notifications, horloge, session.

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            readonly property bool vertical: Config.barVertical

            screen: modelData
            anchors {
                left: true
                top: true
                bottom: vertical
                right: !vertical
            }
            implicitWidth: Theme.barSize
            implicitHeight: Theme.barSize
            exclusiveZone: Theme.barSize
            color: Theme.transparent
            WlrLayershell.namespace: "orbe-bar"

            Rectangle {
                anchors.fill: parent
                color: Theme.surface

                // Bordure côté bureau
                Rectangle {
                    color: Theme.line
                    width: bar.vertical ? 1 : parent.width
                    height: bar.vertical ? parent.height : 1
                    x: bar.vertical ? parent.width - 1 : 0
                    y: bar.vertical ? 0 : parent.height - 1
                }
            }

            GridLayout {
                id: start

                flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                rowSpacing: Theme.space2
                columnSpacing: Theme.space2
                x: bar.vertical ? (bar.width - width) / 2 : Theme.space2
                y: bar.vertical ? Theme.space2 : (bar.height - height) / 2

                // Logo : ouvre le lanceur
                Item {
                    Layout.alignment: Qt.AlignCenter
                    implicitWidth: Theme.barSize - Theme.space3
                    implicitHeight: Theme.barSize - Theme.space3

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusM
                        color: logoMouse.containsMouse || Panels.launcherOpen ? Theme.surface2 : Theme.transparent
                    }

                    OrbeLogo {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                    }

                    MouseArea {
                        id: logoMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Panels.toggleLauncher()
                    }
                }

                Workspaces {
                    Layout.alignment: Qt.AlignCenter
                    vertical: bar.vertical
                }

                ActiveWindow {
                    Layout.alignment: Qt.AlignCenter
                }
            }

            GridLayout {
                id: end

                flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                rowSpacing: Theme.space1
                columnSpacing: Theme.space1
                x: bar.vertical ? (bar.width - width) / 2 : bar.width - width - Theme.space2
                y: bar.vertical ? bar.height - height - Theme.space2 : (bar.height - height) / 2

                Tray {
                    Layout.alignment: Qt.AlignCenter
                    vertical: bar.vertical
                    window: bar
                }

                BarButton {
                    Layout.alignment: Qt.AlignCenter
                    icon: Audio.icon
                    visible: Audio.ready
                    onClicked: Audio.toggleMute()
                    onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
                }

                Battery {
                    Layout.alignment: Qt.AlignCenter
                }

                BarButton {
                    Layout.alignment: Qt.AlignCenter
                    icon: Notifs.doNotDisturb ? "bell-off" : "bell"
                    active: Panels.centerOpen
                    onClicked: Panels.toggleCenter()

                    // Pastille quand des notifications attendent dans le centre.
                    Rectangle {
                        visible: Notifs.count > 0 && !Panels.centerOpen
                        width: 6
                        height: 6
                        radius: 1
                        color: Theme.accent
                        x: parent.width - width - 9
                        y: 9
                    }
                }

                Clock {
                    Layout.alignment: Qt.AlignCenter
                    vertical: bar.vertical
                }

                BarButton {
                    Layout.alignment: Qt.AlignCenter
                    icon: "power"
                    danger: true
                    active: Panels.sessionOpen
                    onClicked: Panels.toggleSession()
                }
            }
        }
    }
}
