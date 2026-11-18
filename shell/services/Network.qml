pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

// Réseau (NetworkManager) : câble, Wi-Fi, réseaux visibles.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var activeWifi: wifi ? (wifi.networks.values.find(n => n.connected) ?? null) : null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool online: wired !== null || activeWifi !== null
    readonly property string icon: wired ? "ethernet" : wifiEnabled ? "wifi" : "wifi-off"
    readonly property string label: wired ? "Connecté par câble" : activeWifi ? activeWifi.name : wifiEnabled ? "Non connecté" : "Wi-Fi coupé"
    // Réseaux Wi-Fi, du plus fort au plus faible, celui en cours en premier.
    readonly property var networks: wifi ? wifi.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []

    function setWifi(on) {
        Networking.wifiEnabled = on;
    }

    // Recherche des réseaux, seulement pendant que la liste est affichée.
    function scan(on) {
        if (wifi)
            wifi.scannerEnabled = on;
    }
}
