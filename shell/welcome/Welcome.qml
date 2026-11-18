// Assistant de bienvenue : ouvert au premier lancement d'un compte (réglage welcomeDone de
// ~/.config/orbe/shell.json), ou par qs -c orbe ipc call welcome open.
// Dans la session live, il propose d'abord d'installer Orbe OS.
// Étapes : bienvenue, apparence, météo, applications, raccourcis. Tout se fait au clavier :
// Entrée pour continuer (en live, à la première étape : installer), Échap pour revenir,
// Tab pour passer d'un choix à l'autre.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel
import qs
import qs.components

Scope {
    id: root

    property bool live: false
    property int step: 0

    Connections {
        target: Panels
        function onWelcomeStepChanged() {
            root.step = Panels.welcomeStep;
        }
    }
    readonly property var steps: ["Bienvenue", "Apparence", "Météo", "Applications", "Raccourcis"]
    property int focusIndex: 0

    // Applications proposées (dépôts officiels d'Arch), installées dans un terminal avec sudo.
    property var apps: [
        { name: "Firefox", detail: "Navigateur web", pkgs: ["firefox", "firefox-i18n-fr"], checked: true },
        { name: "Discord", detail: "Discussions et vocal entre joueurs", pkgs: ["discord"], checked: false },
        { name: "OBS Studio", detail: "Enregistrer et diffuser ses parties", pkgs: ["obs-studio"], checked: false },
        { name: "Visual Studio Code", detail: "Éditeur de code (version libre)", pkgs: ["code"], checked: false },
        { name: "LibreOffice", detail: "Textes, tableurs, présentations", pkgs: ["libreoffice-fresh", "libreoffice-fresh-fr"], checked: false }
    ]

    function finish() {
        Config.welcomeDone = true;
        Panels.welcomeOpen = false;
        step = 0;
    }

    function next() {
        if (step === 3)
            installApps();
        if (step < steps.length - 1)
            step++;
        else
            finish();
    }

    // Session live : l'action principale est l'installation.
    function install() {
        finish();
        Quickshell.execDetached(["orbe-install"]);
    }

    function back() {
        if (step > 0)
            step--;
    }

    function installApps() {
        const pkgs = apps.filter(a => a.checked).flatMap(a => a.pkgs);
        if (pkgs.length === 0)
            return;
        Quickshell.execDetached(["foot", "-H", "-T", "Installation des applications", "sudo", "pacman", "-S", "--needed", ...pkgs]);
    }

    function toggleApp(index) {
        const list = apps.slice();
        list[index] = Object.assign({}, list[index], { checked: !list[index].checked });
        apps = list;
    }

    // Session live : /run/archiso existe.
    Process {
        running: true
        command: ["test", "-d", "/run/archiso"]
        onExited: code => {
            root.live = code === 0;
            if (!Config.welcomeDone)
                Panels.welcomeOpen = true;
        }
    }

    FolderListModel {
        id: wallpapers

        folder: "file:///usr/share/backgrounds/orbe"
        nameFilters: ["*.png", "*.jpg", "*.webp"]
        showDirs: false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: Panels.welcomeOpen && Panels.isActive(modelData)
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
            WlrLayershell.namespace: "orbe-welcome"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onOpenChanged: if (open) content.forceActiveFocus()

            Behavior on progress {
                NumberAnimation {
                    duration: Theme.durSlow
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bg
                opacity: 0.94 * win.progress
            }

            Orb {
                anchors.fill: parent
                visible: win.visible
                opacity: 0.55 * win.progress
                particles: 700
                maxFps: 30
                speed: 0.05
                orbCenter: Qt.point(width * 0.82, height * 0.5)
                orbRadius: Math.min(width, height) * 0.42
            }

            Item {
                id: content

                anchors.fill: parent
                opacity: win.progress
                focus: win.open

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.step === 0 && root.live)
                            root.install();
                        else if (root.step === 3 && root.focusIndex < root.apps.length)
                            root.toggleApp(root.focusIndex);
                        else
                            root.next();
                    } else if (event.key === Qt.Key_Escape) {
                        root.back();
                    } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                        root.focusIndex++;
                    } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                        root.focusIndex = Math.max(0, root.focusIndex - 1);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Rectangle {
                    id: card

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -parent.width * 0.1
                    width: 820
                    height: 560
                    radius: Theme.radiusL
                    color: Theme.panel
                    border.width: 1
                    border.color: Theme.line
                    scale: 0.97 + 0.03 * win.progress

                    // Étapes, en haut
                    Row {
                        id: stepper

                        anchors {
                            left: parent.left
                            top: parent.top
                            margins: Theme.space5
                        }
                        spacing: Theme.space2

                        Repeater {
                            model: root.steps

                            Rectangle {
                                required property string modelData
                                required property int index

                                width: (card.width - Theme.space5 * 2 - Theme.space2 * (root.steps.length - 1)) / root.steps.length
                                height: 36
                                color: Theme.transparent

                                Rectangle {
                                    width: parent.width
                                    height: 3
                                    radius: 2
                                    color: index <= root.step ? Theme.accent : Theme.line2
                                }
                                OText {
                                    y: 12
                                    text: modelData
                                    color: index === root.step ? Theme.text : Theme.muted
                                    font.pixelSize: Theme.textS
                                }
                            }
                        }
                    }

                    // Contenu de l'étape
                    Item {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: stepper.bottom
                            bottom: footer.top
                            margins: Theme.space5
                        }

                        // Bienvenue
                        Column {
                            visible: root.step === 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: Theme.space3

                            OrbeLogo {
                                width: 64
                                height: 64
                            }
                            OText {
                                text: "Bienvenue dans Orbe OS"
                                font.pixelSize: 44
                                font.weight: Font.DemiBold
                            }
                            OText {
                                width: parent.width * 0.8
                                text: root.live
                                    ? "Tu utilises la version live : rien n'est installé sur ce PC. Essaie le bureau et le mode jeu, puis installe Orbe OS quand tu veux."
                                    : "Quelques réglages pour commencer : fond d'écran, barre, météo et applications. Tout se change ensuite dans les réglages."
                                color: Theme.muted
                                font.pixelSize: Theme.textL
                                wrapMode: Text.WordWrap
                                lineHeight: 1.3
                            }
                        }

                        // Apparence : fond d'écran et position de la barre
                        Column {
                            visible: root.step === 1
                            width: parent.width
                            spacing: Theme.space3

                            OText {
                                text: "Fond d'écran"
                                font.pixelSize: Theme.textL
                                font.weight: Font.DemiBold
                            }
                            Row {
                                spacing: Theme.space3

                                Repeater {
                                    model: ["orbe-vivant"].concat(Array.from({ length: wallpapers.count }, (_, i) => wallpapers.get(i, "filePath")))

                                    Rectangle {
                                        id: thumb

                                        required property string modelData
                                        readonly property bool selected: Config.wallpaper === modelData

                                        width: 132
                                        height: 74
                                        radius: Theme.radiusM
                                        color: Theme.bg
                                        border.width: selected ? 2 : 1
                                        border.color: selected ? Theme.accent : Theme.line
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            visible: thumb.modelData !== "orbe-vivant"
                                            source: visible ? "file://" + thumb.modelData : ""
                                            sourceSize: Qt.size(264, 148)
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }
                                        OText {
                                            anchors.centerIn: parent
                                            visible: thumb.modelData === "orbe-vivant"
                                            text: "Orbe vivant"
                                            font.pixelSize: Theme.textS
                                            color: Theme.accent
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Config.wallpaper = thumb.modelData
                                        }
                                    }
                                }
                            }

                            Item {
                                width: 1
                                height: Theme.space3
                            }
                            OText {
                                text: "Barre"
                                font.pixelSize: Theme.textL
                                font.weight: Font.DemiBold
                            }
                            Row {
                                spacing: Theme.space3

                                Repeater {
                                    model: [{ id: "left", label: "À gauche" }, { id: "top", label: "En haut" }]

                                    Rectangle {
                                        id: barChoice

                                        required property var modelData
                                        readonly property bool selected: Config.barPosition === modelData.id

                                        width: 180
                                        height: 44
                                        radius: Theme.radiusM
                                        color: selected ? Theme.accent : Theme.surface2
                                        border.width: selected ? 0 : 1
                                        border.color: Theme.line

                                        OText {
                                            anchors.centerIn: parent
                                            text: barChoice.modelData.label
                                            color: barChoice.selected ? Theme.textOnAccent : Theme.text
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Config.barPosition = barChoice.modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        // Météo
                        Column {
                            visible: root.step === 2
                            width: parent.width
                            spacing: Theme.space3

                            OText {
                                text: "Ta ville, pour la météo du tableau de bord"
                                font.pixelSize: Theme.textL
                                font.weight: Font.DemiBold
                            }
                            Rectangle {
                                width: 420
                                height: 52
                                radius: Theme.radiusM
                                color: Theme.surface2
                                border.width: 1
                                border.color: Theme.line

                                FocusRing {
                                    visible: city.activeFocus
                                    radius: Theme.radiusM
                                }
                                TextInput {
                                    id: city

                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space4
                                    anchors.rightMargin: Theme.space4
                                    verticalAlignment: TextInput.AlignVCenter
                                    focus: root.step === 2 && win.open
                                    color: Theme.text
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.textL
                                    text: Config.weatherCity
                                    onEditingFinished: Config.weatherCity = text.trim()
                                    onAccepted: {
                                        Config.weatherCity = text.trim();
                                        root.next();
                                        content.forceActiveFocus();
                                    }
                                }
                            }
                            OText {
                                text: "Données Open-Meteo, sans compte ni clé. Laisse vide pour ne pas afficher la météo."
                                color: Theme.muted
                                font.pixelSize: Theme.textS
                            }
                        }

                        // Applications
                        Column {
                            visible: root.step === 3
                            width: parent.width
                            spacing: Theme.space2

                            OText {
                                text: "Applications à installer"
                                font.pixelSize: Theme.textL
                                font.weight: Font.DemiBold
                            }
                            OText {
                                text: "Steam, Heroic (Epic, GOG) et le mode jeu sont déjà là. L'installation demande ton mot de passe dans un terminal."
                                color: Theme.muted
                                font.pixelSize: Theme.textS
                            }
                            Repeater {
                                model: root.apps

                                Rectangle {
                                    id: appRow

                                    required property var modelData
                                    required property int index
                                    readonly property bool focused: root.step === 3 && root.focusIndex === index

                                    width: parent.width
                                    height: 52
                                    radius: Theme.radiusM
                                    color: appMouse.containsMouse || focused ? Theme.surface2 : Theme.transparent

                                    FocusRing {
                                        visible: appRow.focused
                                        radius: Theme.radiusM
                                    }
                                    Rectangle {
                                        id: box

                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.space3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        radius: Theme.radiusS
                                        color: appRow.modelData.checked ? Theme.accent : Theme.transparent
                                        border.width: appRow.modelData.checked ? 0 : 1
                                        border.color: Theme.line2

                                        Icon {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            visible: appRow.modelData.checked
                                            name: "check"
                                            color: Theme.textOnAccent
                                            stroke: 2.2
                                        }
                                    }
                                    Column {
                                        anchors.left: box.right
                                        anchors.leftMargin: Theme.space3
                                        anchors.verticalCenter: parent.verticalCenter

                                        OText {
                                            text: appRow.modelData.name
                                        }
                                        OText {
                                            text: appRow.modelData.detail
                                            color: Theme.muted
                                            font.pixelSize: Theme.textS
                                        }
                                    }
                                    MouseArea {
                                        id: appMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleApp(appRow.index)
                                    }
                                }
                            }
                        }

                        // Raccourcis
                        Column {
                            visible: root.step === 4
                            width: parent.width
                            spacing: Theme.space2

                            OText {
                                text: "L'essentiel au clavier"
                                font.pixelSize: Theme.textL
                                font.weight: Font.DemiBold
                            }
                            Grid {
                                columns: 2
                                columnSpacing: Theme.space6
                                rowSpacing: Theme.space2

                                Repeater {
                                    model: [
                                        ["Super", "Lanceur d'applications"],
                                        ["Super + G", "Mode jeu"],
                                        ["Super + D", "Tableau de bord"],
                                        ["Super + A", "Réglages rapides"],
                                        ["Super + Entrée", "Terminal"],
                                        ["Super + E", "Fichiers"],
                                        ["Super + Q", "Fermer la fenêtre"],
                                        ["Super + L", "Verrouiller"],
                                        ["Super + Échap", "Menu de session"],
                                        ["Super + Maj + :", "Tous les raccourcis"]
                                    ]

                                    Row {
                                        required property var modelData

                                        spacing: Theme.space3

                                        Rectangle {
                                            width: 150
                                            height: 30
                                            radius: Theme.radiusS
                                            color: Theme.surface2
                                            border.width: 1
                                            border.color: Theme.line

                                            OText {
                                                anchors.centerIn: parent
                                                text: modelData[0]
                                                mono: true
                                                font.pixelSize: Theme.textS
                                                color: Theme.accent
                                            }
                                        }
                                        OText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData[1]
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Boutons
                    Item {
                        id: footer

                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: Theme.space5
                        }
                        height: 44

                        OButton {
                            anchors.left: parent.left
                            visible: root.step > 0
                            text: "Retour"
                            onClicked: root.back()
                        }

                        Row {
                            anchors.right: parent.right
                            spacing: Theme.space2

                            OButton {
                                visible: root.step === 0 && root.live
                                text: "Installer Orbe OS"
                                accent: true
                                onClicked: root.install()
                            }
                            OButton {
                                text: root.step === 0 ? (root.live ? "Essayer d'abord" : "Commencer") : root.step === root.steps.length - 1 ? "Terminer" : root.step === 3 ? "Installer et continuer" : "Continuer"
                                accent: !(root.step === 0 && root.live)
                                onClicked: root.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
