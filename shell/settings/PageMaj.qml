import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.components

Column {
    id: page

    property var updates: []
    property bool checking: false

    width: parent ? parent.width : 700

    function check() {
        checking = true;
        proc.running = true;
    }

    Process {
        id: proc

        command: ["checkupdates", "--nocolor"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.updates = text.split("\n").filter(l => l.trim()).map(l => {
                    const f = l.split(/\s+/);
                    return { name: f[0], from: f[1], to: f[3] };
                });
                page.checking = false;
            }
        }
        onExited: page.checking = false
    }

    PageTitle {
        title: "Mises à jour"
        subtitle: "Paquets d'Arch et d'Orbe OS. Un instantané du système est pris avant (btrfs) : en cas de souci, il se choisit au démarrage."
    }

    SettingRow {
        title: page.checking ? "Recherche en cours" : page.updates.length === 0 ? "Le système est à jour" : page.updates.length + " mise" + (page.updates.length > 1 ? "s" : "") + " à jour disponible" + (page.updates.length > 1 ? "s" : "")
        Row {
            spacing: Theme.space2
            OButton {
                text: "Rechercher"
                onClicked: page.check()
            }
            OButton {
                visible: page.updates.length > 0
                text: "Tout mettre à jour"
                accent: true
                onClicked: Quickshell.execDetached(["foot", "-T", "Mise à jour d'Orbe OS", "-H", "orbe-update"])
            }
        }
    }

    Repeater {
        model: page.updates.slice(0, 60)
        Item {
            required property var modelData
            width: page.width
            height: 30
            OText {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.name
                mono: true
                font.pixelSize: Theme.textS
            }
            OText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.from + "  ›  " + modelData.to
                mono: true
                color: Theme.muted
                font.pixelSize: Theme.textS
            }
        }
    }

    Component.onCompleted: check()
}
