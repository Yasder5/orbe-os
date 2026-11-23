// Application « Réglages Orbe » : fenêtre du shell (même thème, mêmes services), ouverte par
// qs -c orbe ipc call settings open [page], le lanceur ou l'entrée « Réglages Orbe ».
// Les réglages vont dans ~/.config/orbe/ (shell.json, reglages.json) et s'appliquent à chaud.

import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.components
import qs.services

Scope {
    id: root

    readonly property var pages: [
        { id: "apparence", label: "Apparence", icon: "image" },
        { id: "ecrans", label: "Écrans", icon: "apps" },
        { id: "clavier", label: "Clavier et souris", icon: "keyboard" },
        { id: "son", label: "Son", icon: "speaker" },
        { id: "reseau", label: "Réseau", icon: "wifi" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "jeu", label: "Mode jeu", icon: "gamepad" },
        { id: "energie", label: "Énergie", icon: "leaf" },
        { id: "comptes", label: "Comptes", icon: "lock" },
        { id: "maj", label: "Mises à jour", icon: "restart" },
        { id: "apropos", label: "À propos", icon: "cpu" }
    ]
    property string page: "apparence"

    Connections {
        target: Panels
        function onSettingsPageChanged() {
            if (Panels.settingsPage)
                root.page = Panels.settingsPage;
        }
    }

    LazyLoader {
        active: Panels.settingsOpen

        FloatingWindow {
            id: win

            title: "Réglages Orbe"
            color: Theme.bg
            implicitWidth: 1080
            implicitHeight: 720
            onVisibleChanged: if (!visible) Panels.settingsOpen = false
            Component.onCompleted: Reglages.refreshOutputs()

            // Barre latérale
            Rectangle {
                id: sidebar

                width: 260
                height: parent.height
                color: Theme.surface

                Row {
                    id: brand

                    x: Theme.space4
                    y: Theme.space5
                    spacing: Theme.space3

                    OrbeLogo {
                        width: 32
                        height: 32
                    }
                    OText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Réglages"
                        font.pixelSize: Theme.textL
                        font.weight: Font.DemiBold
                    }
                }

                ListView {
                    id: menu

                    anchors {
                        top: brand.bottom
                        topMargin: Theme.space5
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: Theme.space3
                    }
                    spacing: 2
                    model: root.pages
                    focus: true
                    currentIndex: root.pages.findIndex(p => p.id === root.page)
                    keyNavigationEnabled: true
                    onCurrentIndexChanged: if (currentIndex >= 0) root.page = root.pages[currentIndex].id

                    delegate: ListRow {
                        required property var modelData
                        required property int index

                        width: menu.width
                        icon: modelData.icon
                        title: modelData.label
                        selected: root.page === modelData.id
                        onClicked: root.page = modelData.id
                    }
                }
            }

            Rectangle {
                x: sidebar.width
                width: 1
                height: parent.height
                color: Theme.line
            }

            // Contenu de la page
            Flickable {
                id: flick

                anchors {
                    left: sidebar.right
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 1
                }
                contentHeight: pageLoader.height + Theme.space6 * 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: pageLoader

                    x: Theme.space6
                    y: Theme.space6
                    width: flick.width - Theme.space6 * 2
                    source: "Page" + root.page.charAt(0).toUpperCase() + root.page.slice(1) + ".qml"
                    onSourceChanged: flick.contentY = 0
                }
            }
        }
    }

    IpcHandler {
        target: "settings"

        function open(page: string): void {
            Panels.closeAll();
            if (page)
                root.page = page;
            Panels.settingsOpen = true;
        }
        function close(): void {
            Panels.settingsOpen = false;
        }
    }
}
