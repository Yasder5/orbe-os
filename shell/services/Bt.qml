pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQml.Models

// Bluetooth (BlueZ) : adaptateur par défaut et appareils connus.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)) : []
    readonly property var connected: devices.filter(d => d.connected)
    readonly property string label: !available ? "Pas d'adaptateur" : !enabled ? "Coupé" : connected.length === 1 ? connected[0].name : connected.length > 1 ? `${connected.length} appareils` : "Aucun appareil"

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }

    function scan(on) {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }

    // Appareils appairés marqués « de confiance » : une manette ou un casque se reconnecte
    // alors tout seul (bouton Xbox ou PS, allumage du casque).
    Instantiator {
        model: root.devices

        QtObject {
            required property var modelData
            readonly property bool paired: modelData.paired

            onPairedChanged: if (paired && !modelData.trusted) modelData.trusted = true
            Component.onCompleted: if (paired && !modelData.trusted) modelData.trusted = true
        }
    }
}
