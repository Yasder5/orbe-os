pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Sortie son par défaut (PipeWire) : volume, coupure, et un signal pour l'OSD.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property string icon: muted || volume <= 0.001 ? "volume-mute" : volume < 0.5 ? "volume-low" : "volume"

    // Émis quand le volume change après le démarrage (touches, molette, autre application).
    signal touched

    function setVolume(value) {
        if (!ready)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    // Les premières valeurs arrivent au démarrage : on ne les annonce pas.
    property bool settled: false
    Timer {
        running: true
        interval: 2000
        onTriggered: root.settled = true
    }

    onVolumeChanged: if (settled) touched()
    onMutedChanged: if (settled) touched()
}
