import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.components

Column {
    id: page

    property var info: ({})

    width: parent ? parent.width : 700
    spacing: Theme.space4

    Process {
        running: true
        command: ["sh", "-c", ". /etc/os-release; echo \"version=${VERSION_ID:-rolling}\"; echo \"kernel=$(uname -r)\"; "
            + "echo \"cpu=$(sed -n 's/^model name\\s*: //p' /proc/cpuinfo | head -n1)\"; "
            + "echo \"gpu=$(lspci 2>/dev/null | sed -n 's/.*\\(VGA\\|3D\\|Display\\)[^:]*: //p' | sed 's/Corporation //' | paste -sd ',' -)\"; "
            + "echo \"ram=$(awk '/MemTotal/ {printf \"%.1f Go\", $2/1048576}' /proc/meminfo)\"; "
            + "echo \"disk=$(df -h --output=size,avail / | tail -n1 | awk '{print $2\" libres sur \"$1}')\"; "
            + "echo \"host=$(cat /etc/hostname 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        o[line.slice(0, i)] = line.slice(i + 1);
                }
                page.info = o;
            }
        }
    }

    Row {
        spacing: Theme.space5

        Orb {
            width: 140
            height: 140
            particles: 260
            maxFps: 30
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space1
            OText {
                text: "Orbe OS"
                font.pixelSize: 40
                font.weight: Font.DemiBold
            }
            OText {
                text: "Version " + (page.info.version || "") + " · basé sur Arch Linux"
                color: Theme.muted
            }
            OText {
                text: "github.com/Yasder5/orbe-os"
                color: Theme.accent
                font.pixelSize: Theme.textS
            }
        }
    }

    Column {
        width: parent.width

        Repeater {
            model: [
                ["Nom du PC", "host"], ["Processeur", "cpu"], ["Carte graphique", "gpu"],
                ["Mémoire", "ram"], ["Disque", "disk"], ["Noyau Linux", "kernel"]
            ]
            SettingRow {
                required property var modelData
                title: modelData[0]
                OText {
                    text: page.info[modelData[1]] || ""
                    color: Theme.muted
                    width: Math.min(implicitWidth, 460)
                    elide: Text.ElideRight
                }
            }
        }
    }
}
