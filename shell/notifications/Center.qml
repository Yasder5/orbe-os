// Centre de notifications : historique, Ne pas déranger, tout effacer.
// Panneau qui sort de la barre, comme le lanceur. Échap ou clic à côté pour fermer.

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs
import qs.components
import qs.services

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: Panels.centerOpen && Panels.isActive(modelData)
            readonly property bool vertical: Config.barVertical
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
            WlrLayershell.namespace: "orbe-center"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            Behavior on progress {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Panels.centerOpen = false
            }

            Item {
                x: win.vertical ? Theme.barSize : 0
                y: win.vertical ? 0 : Theme.barSize
                width: win.width - x
                height: win.height - y
                clip: true

                Item {
                    id: panel

                    width: 420
                    height: parent.height - Theme.space3 * 2
                    x: Theme.space3 - (win.vertical ? (1 - win.progress) * (width + 60) : 0)
                    y: Theme.space3 - (win.vertical ? 0 : (1 - win.progress) * (height + 60))
                    opacity: win.progress
                    focus: win.open
                    Keys.onEscapePressed: Panels.centerOpen = false

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

                    // En-tête : titre, nombre, Ne pas déranger, tout effacer.
                    Item {
                        id: header

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: Theme.space4
                        }
                        height: 36

                        OText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Notifications"
                            font.pixelSize: Theme.textL
                            font.weight: Font.DemiBold
                        }

                        Row {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: Theme.space2

                            PanelButton {
                                icon: Notifs.doNotDisturb ? "bell-off" : "bell"
                                label: "Ne pas déranger"
                                active: Notifs.doNotDisturb
                                onClicked: Notifs.toggleDoNotDisturb()
                            }

                            PanelButton {
                                icon: "close"
                                label: "Tout effacer"
                                visible: Notifs.count > 0
                                onClicked: Notifs.clear()
                            }
                        }
                    }

                    ListView {
                        anchors {
                            top: header.bottom
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: Theme.space4
                        }
                        clip: true
                        spacing: Theme.space2
                        model: Notifs.history
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: NotificationCard {
                            required property var modelData

                            width: ListView.view.width
                            notification: modelData
                            popup: false
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: Notifs.count === 0
                            spacing: Theme.space3

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 32
                                height: 32
                                name: Notifs.doNotDisturb ? "bell-off" : "bell"
                                color: Theme.line2
                            }
                            OText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Aucune notification"
                                color: Theme.muted
                            }
                        }
                    }
                }
            }
        }
    }
}
