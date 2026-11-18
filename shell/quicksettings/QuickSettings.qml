// Réglages rapides (Super + A, ou clic sur le son ou le réseau dans la barre) :
// Wi-Fi, Bluetooth, Ne pas déranger, mode nuit, profil d'énergie, volumes, luminosité,
// sortie audio, volume par application, réseaux Wi-Fi et appareils Bluetooth.

import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

Scope {
    id: root

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink && n.audio)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var profiles: [
        { value: PowerProfile.PowerSaver, label: "Économie", icon: "leaf" },
        { value: PowerProfile.Balanced, label: "Équilibré", icon: "speed" },
        { value: PowerProfile.Performance, label: "Performance", icon: "action" }
    ]
    readonly property var profile: profiles.find(p => p.value === PowerProfiles.profile) ?? profiles[1]
    property string section: "audio"
    property string passwordFor: ""

    function nextProfile() {
        const available = PowerProfiles.hasPerformanceProfile ? profiles : profiles.slice(0, 2);
        const i = available.findIndex(p => p.value === PowerProfiles.profile);
        PowerProfiles.profile = available[(i + 1) % available.length].value;
    }

    function appName(node) {
        const p = node.properties ?? {};
        return p["application.name"] || node.description || node.name;
    }

    PwObjectTracker {
        objects: [...root.sinks, ...root.streams, root.source]
    }

    Variants {
        model: Quickshell.screens

        SidePanel {
            id: panel

            namespace: "orbe-quick"
            open: Panels.quickOpen && Panels.isActive(modelData)
            panelWidth: 440
            onCloseRequested: Panels.quickOpen = false
            onOpenChanged: {
                Network.scan(open && root.section === "wifi");
                Bt.scan(open && root.section === "bluetooth");
            }

            Flickable {
                anchors.fill: parent
                contentHeight: column.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: column

                    width: parent.width
                    spacing: Theme.space4

                    OText {
                        text: "Réglages rapides"
                        font.pixelSize: Theme.textL
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: Theme.space2
                        columnSpacing: Theme.space2

                        Tile {
                            Layout.fillWidth: true
                            icon: Network.icon
                            title: "Wi-Fi"
                            subtitle: Network.label
                            active: Network.wifiEnabled
                            available: Network.wifi !== null
                            onClicked: Network.setWifi(!Network.wifiEnabled)
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: Bt.enabled ? "bluetooth" : "bluetooth-off"
                            title: "Bluetooth"
                            subtitle: Bt.label
                            active: Bt.enabled
                            available: Bt.available
                            onClicked: Bt.setEnabled(!Bt.enabled)
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: Notifs.doNotDisturb ? "bell-off" : "bell"
                            title: "Ne pas déranger"
                            subtitle: Notifs.doNotDisturb ? "Activé" : "Désactivé"
                            active: Notifs.doNotDisturb
                            onClicked: Notifs.toggleDoNotDisturb()
                        }
                        Tile {
                            Layout.fillWidth: true
                            icon: "moon"
                            title: "Mode nuit"
                            subtitle: Night.enabled ? `${Config.nightTemperature} K` : "Désactivé"
                            active: Night.enabled
                            onClicked: Night.toggle()
                        }
                        Tile {
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            icon: root.profile.icon
                            title: "Profil d'énergie"
                            subtitle: root.profile.label
                            active: PowerProfiles.profile === PowerProfile.Performance
                            onClicked: root.nextProfile()
                        }
                    }

                    // Volumes et luminosité
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: Theme.space3
                        rowSpacing: Theme.space3

                        Icon {
                            name: Audio.icon
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Audio.toggleMute()
                            }
                        }
                        OSlider {
                            Layout.fillWidth: true
                            value: Audio.muted ? 0 : Audio.volume
                            enabled: Audio.ready
                            onMoved: v => Audio.setVolume(v)
                        }
                        OText {
                            Layout.preferredWidth: 40
                            mono: true
                            font.pixelSize: Theme.textXs
                            color: Theme.muted
                            horizontalAlignment: Text.AlignRight
                            text: `${Math.round((Audio.muted ? 0 : Audio.volume) * 100)}`
                        }

                        Icon {
                            name: "mic"
                            color: root.source && root.source.audio && root.source.audio.muted ? Theme.danger : Theme.text
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
                            }
                        }
                        OSlider {
                            Layout.fillWidth: true
                            value: root.source && root.source.audio ? root.source.audio.volume : 0
                            enabled: root.source !== null && root.source.audio !== null
                            onMoved: v => root.source.audio.volume = v
                        }
                        OText {
                            Layout.preferredWidth: 40
                            mono: true
                            font.pixelSize: Theme.textXs
                            color: Theme.muted
                            horizontalAlignment: Text.AlignRight
                            text: root.source && root.source.audio ? `${Math.round(root.source.audio.volume * 100)}` : "–"
                        }

                        Icon {
                            visible: Brightness.available
                            name: "brightness"
                        }
                        OSlider {
                            Layout.fillWidth: true
                            visible: Brightness.available
                            value: Brightness.level
                            onMoved: v => Brightness.change(Math.round((v - Brightness.level) * 100))
                        }
                        OText {
                            Layout.preferredWidth: 40
                            visible: Brightness.available
                            mono: true
                            font.pixelSize: Theme.textXs
                            color: Theme.muted
                            horizontalAlignment: Text.AlignRight
                            text: `${Math.round(Brightness.level * 100)}`
                        }
                    }

                    // Onglets du bas : son, Wi-Fi, Bluetooth
                    Row {
                        spacing: Theme.space2

                        Repeater {
                            model: [
                                { id: "audio", label: "Son", icon: "speaker" },
                                { id: "wifi", label: "Wi-Fi", icon: "wifi" },
                                { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" }
                            ]

                            PanelButton {
                                required property var modelData

                                icon: modelData.icon
                                label: modelData.label
                                active: root.section === modelData.id
                                onClicked: {
                                    root.section = modelData.id;
                                    Network.scan(modelData.id === "wifi");
                                    Bt.scan(modelData.id === "bluetooth");
                                }
                            }
                        }
                    }

                    // Son : sortie et volume par application
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.section === "audio"
                        spacing: Theme.space2

                        OText {
                            text: "Sortie"
                            font.pixelSize: Theme.textXs
                            mono: true
                            color: Theme.muted
                        }

                        Repeater {
                            model: root.sinks

                            ListRow {
                                required property var modelData

                                Layout.fillWidth: true
                                icon: "speaker"
                                title: modelData.description || modelData.name
                                selected: Pipewire.defaultAudioSink === modelData
                                onClicked: Pipewire.preferredDefaultAudioSink = modelData
                            }
                        }

                        OText {
                            visible: root.streams.length > 0
                            text: "Applications"
                            font.pixelSize: Theme.textXs
                            mono: true
                            color: Theme.muted
                        }

                        Repeater {
                            model: root.streams

                            RowLayout {
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: Theme.space3

                                OText {
                                    Layout.preferredWidth: 120
                                    text: root.appName(modelData)
                                    font.pixelSize: Theme.textS
                                }
                                OSlider {
                                    Layout.fillWidth: true
                                    value: modelData.audio.volume
                                    onMoved: v => modelData.audio.volume = v
                                }
                            }
                        }

                        OText {
                            visible: root.sinks.length === 0
                            text: "Aucune sortie audio"
                            color: Theme.muted
                            font.pixelSize: Theme.textS
                        }
                    }

                    // Wi-Fi : réseaux visibles, mot de passe demandé sur place
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.section === "wifi"
                        spacing: Theme.space2

                        Repeater {
                            model: Network.networks.slice(0, 10)

                            ColumnLayout {
                                id: netItem

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: Theme.space1

                                ListRow {
                                    Layout.fillWidth: true
                                    icon: "wifi"
                                    title: netItem.modelData.name
                                    subtitle: netItem.modelData.connected ? "Connecté" : netItem.modelData.known ? "Enregistré" : `${Math.round(netItem.modelData.signalStrength * 100)} %`
                                    selected: netItem.modelData.connected
                                    onClicked: {
                                        if (netItem.modelData.connected)
                                            netItem.modelData.disconnect();
                                        else if (netItem.modelData.known)
                                            netItem.modelData.connect();
                                        else
                                            root.passwordFor = netItem.modelData.name;
                                    }
                                }

                                // Mot de passe d'un nouveau réseau
                                Rectangle {
                                    Layout.fillWidth: true
                                    visible: root.passwordFor === netItem.modelData.name
                                    height: 44
                                    radius: Theme.radiusM
                                    color: Theme.surface2
                                    border.width: 1
                                    border.color: Theme.line

                                    FocusRing {
                                        visible: psk.activeFocus
                                        radius: Theme.radiusM
                                    }

                                    TextInput {
                                        id: psk

                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.space3
                                        anchors.rightMargin: Theme.space3
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: TextInput.Password
                                        passwordCharacter: "•"
                                        color: Theme.text
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.textM
                                        focus: visible
                                        onAccepted: {
                                            netItem.modelData.connectWithPsk(text);
                                            text = "";
                                            root.passwordFor = "";
                                        }
                                        Keys.onEscapePressed: root.passwordFor = ""

                                        OText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: psk.text === ""
                                            text: "Mot de passe, puis Entrée"
                                            color: Theme.muted
                                            font.pixelSize: Theme.textS
                                        }
                                    }
                                }
                            }
                        }

                        OText {
                            visible: Network.networks.length === 0
                            text: Network.wifi === null ? "Pas de carte Wi-Fi" : Network.wifiEnabled ? "Recherche des réseaux" : "Wi-Fi coupé"
                            color: Theme.muted
                            font.pixelSize: Theme.textS
                        }
                    }

                    // Bluetooth : appareils connus et à proximité
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.section === "bluetooth"
                        spacing: Theme.space2

                        Repeater {
                            model: Bt.devices.slice(0, 10)

                            ListRow {
                                required property var modelData

                                Layout.fillWidth: true
                                icon: "bluetooth"
                                title: modelData.name || modelData.address
                                subtitle: modelData.connected ? (modelData.batteryAvailable ? `Connecté, batterie ${Math.round(modelData.battery * 100)} %` : "Connecté")
                                                              : modelData.paired ? "Associé" : modelData.pairing ? "Association" : "À proximité"
                                selected: modelData.connected
                                onClicked: {
                                    if (modelData.connected)
                                        modelData.disconnect();
                                    else if (modelData.paired)
                                        modelData.connect();
                                    else
                                        modelData.pair();
                                }
                            }
                        }

                        OText {
                            visible: Bt.devices.length === 0
                            text: !Bt.available ? "Pas d'adaptateur Bluetooth" : Bt.enabled ? "Recherche des appareils" : "Bluetooth coupé"
                            color: Theme.muted
                            font.pixelSize: Theme.textS
                        }
                    }
                }
            }
        }
    }
}
