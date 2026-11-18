pragma Singleton

import Quickshell
import QtQuick
import qs

// Mode nuit : filtre de lumière bleue par hyprsunset (lancé au démarrage de la session).
Singleton {
    id: root

    readonly property bool enabled: Config.nightLight

    function toggle() {
        Config.nightLight = !Config.nightLight;
    }

    function apply() {
        if (enabled)
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(Config.nightTemperature)]);
        else
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
    }

    onEnabledChanged: apply()

    // hyprsunset démarre en même temps que le shell : on applique le réglage un peu après.
    Timer {
        running: true
        interval: 3000
        onTriggered: root.apply()
    }
}
