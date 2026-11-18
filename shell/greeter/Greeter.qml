// Greeter Orbe : orbe animé, heure, compte, mot de passe et choix de la session.
// L'authentification passe par greetd (Quickshell.Services.Greetd) ; la session lancée est
// orbe-session, qui ouvre le bureau ou le mode jeu.

import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import qs
import qs.components

Scope {
    id: root

    property var users: []
    property int userIndex: 0
    readonly property var user: users[userIndex] ?? null
    property string password: ""
    property string message: Greetd.available ? "" : "greetd ne répond pas : aperçu seulement"
    property bool busy: false
    // Session : dernière utilisée, bureau ou mode jeu (argument de orbe-session).
    readonly property var sessions: [
        { id: "", label: "Dernière session", icon: "restart" },
        { id: "bureau", label: "Bureau", icon: "apps" },
        { id: "jeu", label: "Mode jeu", icon: "gamepad" }
    ]
    property int sessionIndex: 0

    function submit() {
        if (busy || !user)
            return;
        busy = true;
        message = "";
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        Greetd.createSession(user.name);
    }

    // Comptes humains de /etc/passwd (UID 1000 à 59999, avec un vrai shell).
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const list = [];
            for (const line of text().split("\n")) {
                const f = line.split(":");
                const uid = parseInt(f[2]);
                if (f.length < 7 || uid < 1000 || uid >= 60000 || /nologin|false$/.test(f[6]))
                    continue;
                const gecos = (f[4] || "").split(",")[0];
                list.push({ name: f[0], display: gecos || f[0] });
            }
            root.users = list;
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.password);
            } else if (error) {
                root.message = message;
            }
        }
        function onAuthFailure(message) {
            root.busy = false;
            root.password = "";
            root.message = "Mot de passe incorrect";
        }
        function onError(error) {
            root.busy = false;
            root.message = error;
        }
        function onReadyToLaunch() {
            const s = root.sessions[root.sessionIndex].id;
            Greetd.launch(s ? ["orbe-session", s] : ["orbe-session"]);
        }
    }

    FloatingWindow {
        id: win

        color: Theme.bg
        implicitWidth: 1280
        implicitHeight: 800

        SystemClock {
            id: clock

            precision: SystemClock.Minutes
        }

        Orb {
            anchors.fill: parent
            particles: 900
            maxFps: 30
            speed: 0.05
            background: Theme.bg
            halo: 0.06
            orbCenter: Qt.point(width * 0.68, height * 0.5)
            orbRadius: Math.min(width, height) * 0.4
            dotSize: Math.max(1.2, height / 480)
        }

        // Heure et date, en haut à gauche
        Column {
            x: parent.width * 0.08
            y: parent.height * 0.1
            spacing: Theme.space1

            OText {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: 96
                font.weight: Font.Light
                font.letterSpacing: -2
            }
            OText {
                text: clock.date.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                font.pixelSize: Theme.textL
                color: Theme.muted
            }
        }

        // Carte de connexion
        Rectangle {
            id: card

            x: parent.width * 0.08
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: parent.height * 0.08
            width: 400
            height: content.implicitHeight + Theme.space5 * 2
            radius: Theme.radiusL
            color: Theme.panel
            border.width: 1
            border.color: Theme.line

            Column {
                id: content

                anchors.fill: parent
                anchors.margins: Theme.space5
                spacing: Theme.space4

                // Compte (flèches haut et bas pour en changer)
                Row {
                    spacing: Theme.space3

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: Theme.accent

                        OText {
                            anchors.centerIn: parent
                            text: root.user ? root.user.display.charAt(0).toUpperCase() : "?"
                            color: Theme.textOnAccent
                            font.pixelSize: Theme.textXl
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        OText {
                            text: root.user ? root.user.display : "Aucun compte"
                            font.pixelSize: Theme.textL
                            font.weight: Font.DemiBold
                        }
                        OText {
                            text: root.users.length > 1 ? "↑ ↓ changer de compte" : (root.user ? root.user.name : "")
                            color: Theme.muted
                            font.pixelSize: Theme.textS
                        }
                    }
                }

                // Mot de passe
                Rectangle {
                    width: parent.width
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
                        Keys.onUpPressed: root.userIndex = Math.max(0, root.userIndex - 1)
                        Keys.onDownPressed: root.userIndex = Math.min(root.users.length - 1, root.userIndex + 1)
                        Keys.onTabPressed: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length

                        OText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: root.busy ? "Ouverture de la session" : "Mot de passe"
                            color: Theme.muted
                            font.pixelSize: Theme.textL
                        }
                    }
                }

                // Session (Tab pour changer)
                Row {
                    spacing: Theme.space2

                    Repeater {
                        model: root.sessions

                        Rectangle {
                            id: chip

                            required property var modelData
                            required property int index
                            readonly property bool selected: root.sessionIndex === index

                            width: chipRow.implicitWidth + Theme.space3 * 2
                            height: 34
                            radius: Theme.radiusS
                            color: selected ? Theme.accent : chipMouse.containsMouse ? Theme.surface2 : Theme.transparent
                            border.width: selected ? 0 : 1
                            border.color: Theme.line

                            Row {
                                id: chipRow

                                anchors.centerIn: parent
                                spacing: Theme.space2

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: chip.modelData.icon
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    color: chip.selected ? Theme.textOnAccent : Theme.muted
                                }
                                OText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.modelData.label
                                    color: chip.selected ? Theme.textOnAccent : Theme.text
                                    font.pixelSize: Theme.textS
                                }
                            }

                            MouseArea {
                                id: chipMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.sessionIndex = chip.index;
                                    input.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                OText {
                    width: parent.width
                    height: 20
                    text: root.message
                    color: Theme.danger
                    font.pixelSize: Theme.textS
                    elide: Text.ElideRight
                }
            }
        }

        // Éteindre et redémarrer, en bas à gauche
        Row {
            x: parent.width * 0.08
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.space6
            spacing: Theme.space2

            Repeater {
                model: [
                    { label: "Redémarrer", icon: "restart", cmd: ["systemctl", "reboot"] },
                    { label: "Éteindre", icon: "power", cmd: ["systemctl", "poweroff"] }
                ]

                Rectangle {
                    id: action

                    required property var modelData

                    width: actionRow.implicitWidth + Theme.space4 * 2
                    height: 40
                    radius: Theme.radiusM
                    color: actionMouse.containsMouse ? Theme.surface2 : Theme.transparent
                    border.width: 1
                    border.color: Theme.line

                    Row {
                        id: actionRow

                        anchors.centerIn: parent
                        spacing: Theme.space2

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: action.modelData.icon
                            implicitWidth: 18
                            implicitHeight: 18
                            color: Theme.muted
                        }
                        OText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: action.modelData.label
                            color: Theme.muted
                            font.pixelSize: Theme.textS
                        }
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(action.modelData.cmd)
                    }
                }
            }
        }

        // Signature
        OText {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.space6
            text: "Orbe OS"
            color: Theme.muted
            font.pixelSize: Theme.textS
            font.letterSpacing: 2
        }
    }
}
