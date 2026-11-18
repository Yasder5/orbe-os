import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.components
import qs.services

Column {
    id: page

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var outputs: nodes.filter(n => n.isSink)
    readonly property var inputs: nodes.filter(n => !n.isSink)

    width: parent ? parent.width : 700

    PwObjectTracker {
        objects: page.nodes
    }

    PageTitle {
        title: "Son"
        subtitle: "Sortie, entrée et volume. Les touches multimédia règlent la sortie choisie."
    }

    SettingRow {
        title: "Volume"
        subtitle: Audio.muted ? "Coupé" : Math.round(Audio.volume * 100) + " %"
        Row {
            spacing: Theme.space3
            OSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: 220
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
            OSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: !Audio.muted
                onToggled: Audio.toggleMute()
            }
        }
    }

    OText {
        text: "Sortie"
        font.weight: Font.DemiBold
        topPadding: Theme.space5
        bottomPadding: Theme.space2
    }
    Repeater {
        model: page.outputs
        ListRow {
            required property var modelData
            width: page.width
            icon: "speaker"
            title: modelData.description || modelData.nickname || modelData.name
            selected: Pipewire.defaultAudioSink === modelData
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    OText {
        text: "Entrée"
        font.weight: Font.DemiBold
        topPadding: Theme.space5
        bottomPadding: Theme.space2
    }
    Repeater {
        model: page.inputs
        ListRow {
            required property var modelData
            width: page.width
            icon: "mic"
            title: modelData.description || modelData.nickname || modelData.name
            selected: Pipewire.defaultAudioSource === modelData
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
    OText {
        visible: page.nodes.length === 0
        text: "PipeWire ne répond pas."
        color: Theme.muted
    }
}
