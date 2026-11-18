// OSD : petite jauge accent au bord droit de l'écran pour le volume, la luminosité
// et le verrouillage majuscules. Ne prend aucun clic.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs
import qs.components
import qs.services

Scope {
    id: root

    property string kind: "volume"
    property bool shown: false

    readonly property real value: kind === "volume" ? (Audio.muted ? 0 : Audio.volume) : kind === "brightness" ? Brightness.level : (Keyboard.capsLock ? 1 : 0)
    readonly property string icon: kind === "volume" ? Audio.icon : kind === "brightness" ? "brightness" : "capslock"
    readonly property string label: kind === "capslock" ? (Keyboard.capsLock ? "MAJ" : "maj") : `${Math.round(value * 100)}`

    function show(what) {
        kind = what;
        shown = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onTouched() {
            root.show("volume");
            Sounds.play("audio-volume-change");
        }
    }
    Connections {
        target: Brightness
        function onTouched() {
            root.show("brightness");
        }
    }
    Connections {
        target: Keyboard
        function onTouched() {
            root.show("capslock");
        }
    }

    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.shown = false
    }

    // qs -c orbe ipc call osd flash volume|brightness|capslock (« show » est réservé par la commande qs)
    IpcHandler {
        target: "osd"

        function flash(kind: string): void {
            root.show(kind);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            property real progress: root.shown && Panels.isActive(modelData) ? 1 : 0

            screen: modelData
            visible: progress > 0
            anchors.right: true
            margins.right: Theme.space3
            implicitWidth: 56 + 40
            implicitHeight: 232 + 40
            exclusiveZone: 0
            color: Theme.transparent
            mask: Region {}
            WlrLayershell.namespace: "orbe-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            Behavior on progress {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }

            Item {
                id: osd

                width: 56
                height: 232
                anchors.verticalCenter: parent.verticalCenter
                x: 20 + (1 - win.progress) * 40
                opacity: win.progress

                RectangularShadow {
                    anchors.fill: box
                    offset.y: 18
                    blur: 40
                    radius: Theme.radiusL
                    color: Theme.shadow
                }

                Rectangle {
                    id: box

                    anchors.fill: parent
                    radius: Theme.radiusL
                    color: Theme.panel
                    border.width: 1
                    border.color: Theme.line
                }

                OText {
                    id: valueLabel

                    anchors {
                        top: parent.top
                        topMargin: Theme.space3
                        horizontalCenter: parent.horizontalCenter
                    }
                    mono: true
                    font.pixelSize: Theme.textXs
                    color: root.kind === "capslock" && Keyboard.capsLock ? Theme.accent : Theme.muted
                    text: root.label
                }

                // Jauge verticale
                Rectangle {
                    id: track

                    anchors {
                        top: valueLabel.bottom
                        bottom: glyph.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Theme.space2
                        bottomMargin: Theme.space3
                    }
                    width: 6
                    radius: 2
                    color: Theme.line

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: parent.height * Math.max(0, Math.min(1, root.value))
                        radius: 2
                        color: Theme.accent

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.durFast
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.curve
                            }
                        }
                    }
                }

                Icon {
                    id: glyph

                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.space3
                        horizontalCenter: parent.horizontalCenter
                    }
                    name: root.icon
                    color: root.kind === "capslock" && Keyboard.capsLock ? Theme.accent : Theme.text
                }
            }
        }
    }
}
