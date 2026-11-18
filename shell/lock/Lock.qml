// Écran de verrouillage (protocole ext-session-lock) : orbe animé, heure en grand, champ de mot
// de passe avec l'anneau de focus, média en cours. Le mot de passe est vérifié par PAM
// (lock/pam/orbe-lock). Si le shell s'arrête pendant le verrouillage, Hyprland garde l'écran
// verrouillé : la session n'est jamais exposée.

import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import qs
import qs.components

Scope {
    id: root

    property string password: ""
    property string message: ""
    property bool busy: false
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null

    function submit() {
        if (busy)
            return;
        busy = true;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam

        configDirectory: "pam"
        config: "orbe-lock"
        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            root.busy = false;
            root.password = "";
            if (result === PamResult.Success) {
                Panels.locked = false;
            } else {
                root.message = result === PamResult.MaxTries ? "Trop d'essais, patiente un instant" : "Mot de passe incorrect";
            }
        }
    }

    WlSessionLock {
        locked: Panels.locked

        WlSessionLockSurface {
            id: surface

            color: Theme.bg

            SystemClock {
                id: clock

                precision: SystemClock.Minutes
            }

            Orb {
                anchors.fill: parent
                particles: 900
                maxFps: 30
                speed: 0.06
                background: Theme.bg
                halo: 0.06
                orbRadius: Math.min(width, height) * 0.36
                dotSize: Math.max(1.2, height / 480)
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.space2

                OText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, Config.clock24h ? "HH:mm" : "hh:mm")
                    font.pixelSize: 128
                    font.weight: Font.Light
                    font.letterSpacing: -2
                }

                OText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.date.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                    font.pixelSize: Theme.textL
                    color: Theme.muted
                }

                Item {
                    width: 1
                    height: Theme.space6
                }

                // Champ de mot de passe
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    height: 52
                    radius: Theme.radiusM
                    color: Theme.surface2
                    border.width: 1
                    border.color: Theme.line

                    FocusRing {
                        visible: input.activeFocus
                        radius: Theme.radiusM
                    }

                    Icon {
                        id: lockIcon

                        anchors {
                            left: parent.left
                            leftMargin: Theme.space4
                            verticalCenter: parent.verticalCenter
                        }
                        name: "lock"
                        color: root.busy ? Theme.accent : Theme.muted
                    }

                    TextInput {
                        id: input

                        anchors {
                            left: lockIcon.right
                            right: parent.right
                            leftMargin: Theme.space3
                            rightMargin: Theme.space4
                            verticalCenter: parent.verticalCenter
                        }
                        focus: true
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        enabled: !root.busy
                        color: Theme.text
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.textL
                        clip: true
                        text: root.password
                        onTextEdited: root.password = text
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.password = ""

                        OText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: root.busy ? "Vérification" : "Mot de passe"
                            color: Theme.muted
                            font.pixelSize: Theme.textL
                        }
                    }
                }

                OText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 24
                    text: root.message
                    color: Theme.danger
                    font.pixelSize: Theme.textS
                }
            }

            // Média en cours, en bas de l'écran
            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: Theme.space6
                }
                visible: root.player !== null
                width: 380
                height: 72
                radius: Theme.radiusL
                color: Theme.panel
                border.width: 1
                border.color: Theme.line

                Row {
                    anchors.fill: parent
                    anchors.margins: Theme.space3
                    spacing: Theme.space3

                    Rectangle {
                        width: 48
                        height: 48
                        radius: Theme.radiusS
                        color: Theme.surface2
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.player ? root.player.trackArtUrl : ""
                            sourceSize: Qt.size(96, 96)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        width: parent.width - 48 - 40 - Theme.space3 * 2
                        anchors.verticalCenter: parent.verticalCenter

                        OText {
                            width: parent.width
                            text: root.player ? root.player.trackTitle : ""
                            font.weight: Font.Medium
                        }
                        OText {
                            width: parent.width
                            text: root.player ? root.player.trackArtist : ""
                            font.pixelSize: Theme.textS
                            color: Theme.muted
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 40
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.radiusM
                        color: playMouse.containsMouse ? Theme.surface2 : Theme.transparent

                        Icon {
                            anchors.centerIn: parent
                            name: root.player && root.player.isPlaying ? "pause" : "play"
                        }

                        MouseArea {
                            id: playMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.player) root.player.togglePlaying()
                        }
                    }
                }
            }
        }
    }
}
