// Tableau de bord (Super + D, ou clic sur l'horloge) : panneau qui sort de la barre.
// Onglets : Accueil (heure, météo, calendrier, lecteur), Système (graphes), Média (lecteur
// détaillé et visualiseur cava). ← → ou Tab pour changer d'onglet, Échap pour fermer.

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

Scope {
    id: root

    readonly property var tabs: [
        { id: "accueil", label: "Accueil", icon: "home" },
        { id: "systeme", label: "Système", icon: "chart" },
        { id: "media", label: "Média", icon: "music" }
    ]
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool open: Panels.dashboardOpen
    property var bars: []

    function moveTab(step) {
        const i = tabs.findIndex(t => t.id === Panels.dashboardTab);
        Panels.dashboardTab = tabs[(i + step + tabs.length) % tabs.length].id;
    }

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // Les mesures et le visualiseur ne tournent que quand leur onglet est affiché.
    Binding {
        target: SystemStats
        property: "active"
        value: root.open && Panels.dashboardTab === "systeme"
    }

    Process {
        running: root.open && Panels.dashboardTab === "media"
        command: ["cava", "-p", Quickshell.shellDir + "/dashboard/cava.conf"]
        stdout: SplitParser {
            onRead: data => root.bars = data.split(";").filter(v => v !== "").map(v => Number(v) / 1000)
        }
        onRunningChanged: if (!running) root.bars = []
    }

    // Avancement de la lecture : MPRIS ne l'envoie pas en continu, on le redemande.
    Timer {
        running: root.open && root.player !== null && root.player.isPlaying
        repeat: true
        interval: 1000
        onTriggered: root.player.positionChanged()
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    component Card: Rectangle {
        radius: Theme.radiusL
        color: Theme.surface2
        border.width: 1
        border.color: Theme.line
    }

    component Player: Item {
        id: playerView

        property bool big: false

        implicitHeight: big ? 420 : 104

        OText {
            anchors.centerIn: parent
            visible: root.player === null
            text: "Rien en lecture"
            color: Theme.muted
        }

        Rectangle {
            id: art

            visible: root.player !== null
            width: playerView.big ? parent.width : 80
            height: playerView.big ? 260 : 80
            radius: Theme.radiusM
            color: Theme.bg
            clip: true

            Image {
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                sourceSize: Qt.size(art.width * 2, art.height * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            visible: root.player !== null
            x: playerView.big ? 0 : art.width + Theme.space4
            y: playerView.big ? art.height + Theme.space4 : 0
            width: parent.width - x
            spacing: Theme.space1

            OText {
                width: parent.width
                text: root.player ? root.player.trackTitle || "Sans titre" : ""
                font.pixelSize: playerView.big ? Theme.textL : Theme.textM
                font.weight: Font.DemiBold
            }
            OText {
                width: parent.width
                text: root.player ? [root.player.trackArtist, root.player.identity].filter(s => s).join("  ·  ") : ""
                font.pixelSize: Theme.textS
                color: Theme.muted
            }

            Item {
                width: 1
                height: Theme.space2
            }

            // Progression
            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: Theme.line

                Rectangle {
                    height: parent.height
                    radius: 2
                    color: Theme.accent
                    width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                }
            }

            Item {
                width: parent.width
                height: 40

                OText {
                    anchors.verticalCenter: parent.verticalCenter
                    mono: true
                    font.pixelSize: Theme.textXs
                    color: Theme.muted
                    text: root.player && root.player.length > 0 ? `${root.time(root.player.position)} / ${root.time(root.player.length)}` : ""
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space1

                    Repeater {
                        model: [
                            { icon: "previous", run: () => root.player.previous() },
                            { icon: root.player && root.player.isPlaying ? "pause" : "play", run: () => root.player.togglePlaying() },
                            { icon: "next", run: () => root.player.next() }
                        ]

                        Rectangle {
                            required property var modelData

                            width: 36
                            height: 36
                            radius: Theme.radiusM
                            color: ctl.containsMouse ? Theme.line : Theme.transparent

                            Icon {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                name: parent.modelData.icon
                            }

                            MouseArea {
                                id: ctl

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.player) parent.modelData.run()
                            }
                        }
                    }
                }
            }
        }
    }

    component Stat: RowLayout {
        property string icon: "cpu"
        property string label: ""
        property string value: ""
        property var history: []
        property real maximum: 1

        spacing: Theme.space3

        Icon {
            name: parent.icon
            color: Theme.muted
        }
        Column {
            Layout.preferredWidth: 150

            OText {
                text: parent.parent.label
                font.pixelSize: Theme.textS
            }
            OText {
                text: parent.parent.value
                mono: true
                font.pixelSize: Theme.textXs
                color: Theme.muted
            }
        }
        Sparkline {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            values: parent.history
            maximum: parent.maximum
        }
    }

    Variants {
        model: Quickshell.screens

        SidePanel {
            id: panel

            namespace: "orbe-dashboard"
            open: Panels.dashboardOpen && Panels.isActive(modelData)
            panelWidth: 720
            panelHeight: 640
            onCloseRequested: Panels.dashboardOpen = false

            Item {
                anchors.fill: parent
                focus: panel.open
                Keys.onLeftPressed: root.moveTab(-1)
                Keys.onRightPressed: root.moveTab(1)
                Keys.onTabPressed: root.moveTab(1)
                Keys.onBacktabPressed: root.moveTab(-1)
                Keys.onEscapePressed: Panels.dashboardOpen = false

                Row {
                    id: tabBar

                    spacing: Theme.space2

                    Repeater {
                        model: root.tabs

                        PanelButton {
                            required property var modelData

                            icon: modelData.icon
                            label: modelData.label
                            active: Panels.dashboardTab === modelData.id
                            onClicked: Panels.dashboardTab = modelData.id
                        }
                    }
                }

                // Accueil
                Item {
                    anchors {
                        top: tabBar.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        topMargin: Theme.space5
                    }
                    visible: Panels.dashboardTab === "accueil"

                    Column {
                        id: hero

                        OText {
                            text: Qt.formatDateTime(clock.date, Config.clock24h ? "HH:mm" : "hh:mm")
                            font.pixelSize: Theme.textHuge
                            font.weight: Font.Light
                            font.letterSpacing: -1
                        }
                        OText {
                            text: clock.date.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM yyyy")
                            font.pixelSize: Theme.textM
                            color: Theme.muted
                        }
                    }

                    // Météo
                    Card {
                        id: weather

                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        width: 330
                        height: 116

                        Row {
                            anchors {
                                left: parent.left
                                top: parent.top
                                margins: Theme.space4
                            }
                            spacing: Theme.space3
                            visible: Weather.current !== null

                            Icon {
                                width: 36
                                height: 36
                                name: Weather.current ? Weather.current.icon : "cloud"
                                color: Theme.accent
                            }
                            Column {
                                OText {
                                    text: Weather.current ? `${Weather.current.temperature}°` : ""
                                    font.pixelSize: Theme.textXl
                                    font.weight: Font.DemiBold
                                }
                                OText {
                                    text: Weather.current ? `${Weather.current.label}, ressenti ${Weather.current.feels}°` : ""
                                    font.pixelSize: Theme.textXs
                                    color: Theme.muted
                                }
                            }
                        }

                        OText {
                            anchors {
                                right: parent.right
                                top: parent.top
                                margins: Theme.space4
                            }
                            text: Weather.place || Config.weatherCity
                            font.pixelSize: Theme.textXs
                            mono: true
                            color: Theme.muted
                        }

                        // Prévisions des jours suivants
                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: Theme.space3
                                leftMargin: Theme.space4
                            }
                            visible: Weather.days.length > 0
                            spacing: Theme.space4

                            Repeater {
                                model: Weather.days.slice(1, 5)

                                Row {
                                    required property var modelData

                                    spacing: Theme.space1

                                    OText {
                                        text: modelData.date.toLocaleDateString(Qt.locale("fr_FR"), "ddd").replace(".", "")
                                        font.pixelSize: Theme.textXs
                                        color: Theme.muted
                                    }
                                    Icon {
                                        width: 14
                                        height: 14
                                        name: modelData.icon
                                    }
                                    OText {
                                        text: `${modelData.max}°`
                                        font.pixelSize: Theme.textXs
                                        mono: true
                                    }
                                }
                            }
                        }

                        OText {
                            anchors.centerIn: parent
                            visible: Weather.current === null
                            text: Weather.failed ? "Météo indisponible" : "Météo en cours de chargement"
                            color: Theme.muted
                            font.pixelSize: Theme.textS
                        }
                    }

                    // Calendrier du mois, semaine commençant le lundi
                    Card {
                        id: calendar

                        readonly property date today: clock.date
                        readonly property int year: today.getFullYear()
                        readonly property int month: today.getMonth()
                        readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
                        readonly property int days: new Date(year, month + 1, 0).getDate()

                        anchors {
                            top: weather.bottom
                            left: parent.left
                            topMargin: Theme.space4
                        }
                        width: 330
                        height: 300

                        OText {
                            id: monthLabel

                            anchors {
                                left: parent.left
                                top: parent.top
                                margins: Theme.space4
                            }
                            text: calendar.today.toLocaleDateString(Qt.locale("fr_FR"), "MMMM yyyy")
                            font.weight: Font.DemiBold
                        }

                        Grid {
                            anchors {
                                top: monthLabel.bottom
                                left: parent.left
                                right: parent.right
                                margins: Theme.space4
                            }
                            columns: 7
                            rowSpacing: Theme.space1
                            columnSpacing: 0

                            Repeater {
                                model: ["L", "M", "M", "J", "V", "S", "D"]

                                OText {
                                    required property string modelData

                                    width: (calendar.width - Theme.space4 * 2) / 7
                                    height: 28
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData
                                    mono: true
                                    font.pixelSize: Theme.textXs
                                    color: Theme.muted
                                }
                            }

                            Repeater {
                                model: calendar.offset + calendar.days

                                Item {
                                    required property int index
                                    readonly property int day: index - calendar.offset + 1
                                    readonly property bool isToday: day === calendar.today.getDate()

                                    width: (calendar.width - Theme.space4 * 2) / 7
                                    height: 30

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 30
                                        height: 26
                                        radius: Theme.radiusS
                                        visible: parent.isToday
                                        color: Theme.accent
                                    }
                                    OText {
                                        anchors.centerIn: parent
                                        visible: parent.day > 0
                                        text: parent.day
                                        mono: true
                                        font.pixelSize: Theme.textS
                                        color: parent.isToday ? Theme.textOnAccent : Theme.text
                                    }
                                }
                            }
                        }
                    }

                    // Lecteur multimédia
                    Card {
                        anchors {
                            top: weather.bottom
                            left: calendar.right
                            right: parent.right
                            topMargin: Theme.space4
                            leftMargin: Theme.space4
                        }
                        height: 300

                        OText {
                            id: mediaTitle

                            anchors {
                                left: parent.left
                                top: parent.top
                                margins: Theme.space4
                            }
                            text: "Lecture"
                            font.weight: Font.DemiBold
                        }

                        Player {
                            anchors {
                                top: mediaTitle.bottom
                                left: parent.left
                                right: parent.right
                                margins: Theme.space4
                            }
                        }
                    }
                }

                // Système
                ColumnLayout {
                    anchors {
                        top: tabBar.bottom
                        left: parent.left
                        right: parent.right
                        topMargin: Theme.space5
                    }
                    visible: Panels.dashboardTab === "systeme"
                    spacing: Theme.space4

                    Stat {
                        Layout.fillWidth: true
                        icon: "cpu"
                        label: "Processeur"
                        value: `${Math.round(SystemStats.cpu * 100)} %` + (SystemStats.cpuTemp > 0 ? `  ·  ${Math.round(SystemStats.cpuTemp)}°C` : "")
                        history: SystemStats.cpuHistory
                    }
                    Stat {
                        Layout.fillWidth: true
                        icon: "memory"
                        label: "Mémoire"
                        value: `${SystemStats.bytes(SystemStats.memUsed)} / ${SystemStats.bytes(SystemStats.memTotal)}`
                        history: SystemStats.memHistory
                    }
                    Stat {
                        Layout.fillWidth: true
                        visible: SystemStats.gpu >= 0
                        icon: "gpu"
                        label: SystemStats.gpuName ? `Carte graphique (${SystemStats.gpuName})` : "Carte graphique"
                        value: `${Math.round(SystemStats.gpu * 100)} %` + (SystemStats.gpuTemp > 0 ? `  ·  ${Math.round(SystemStats.gpuTemp)}°C` : "")
                        history: SystemStats.gpuHistory
                    }
                    Stat {
                        Layout.fillWidth: true
                        icon: "network"
                        label: "Réseau"
                        value: `↓ ${SystemStats.bytes(SystemStats.rx, true)}  ↑ ${SystemStats.bytes(SystemStats.tx, true)}`
                        history: SystemStats.rxHistory
                        maximum: 0
                    }

                    // Disque principal
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space3

                        Icon {
                            name: "disk"
                            color: Theme.muted
                        }
                        Column {
                            Layout.preferredWidth: 150

                            OText {
                                text: "Disque"
                                font.pixelSize: Theme.textS
                            }
                            OText {
                                text: `${SystemStats.bytes(SystemStats.diskUsed)} / ${SystemStats.bytes(SystemStats.diskSize)}`
                                mono: true
                                font.pixelSize: Theme.textXs
                                color: Theme.muted
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 2
                            color: Theme.line

                            Rectangle {
                                width: parent.width * SystemStats.disk
                                height: parent.height
                                radius: 2
                                color: SystemStats.disk > 0.9 ? Theme.danger : Theme.accent
                            }
                        }
                    }
                }

                // Média
                Item {
                    anchors {
                        top: tabBar.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        topMargin: Theme.space5
                    }
                    visible: Panels.dashboardTab === "media"

                    Player {
                        id: bigPlayer

                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: 420
                        big: true
                    }

                    // Visualiseur audio : barres citron
                    Row {
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                        height: 110
                        spacing: 4

                        Repeater {
                            model: 32

                            Rectangle {
                                required property int index

                                anchors.bottom: parent.bottom
                                width: (bigPlayer.width - 31 * 4) / 32
                                height: Math.max(2, 110 * (root.bars[index] ?? 0))
                                radius: 1
                                color: Theme.accent
                                opacity: 0.35 + 0.65 * (root.bars[index] ?? 0)
                            }
                        }
                    }
                }
            }
        }
    }
}
