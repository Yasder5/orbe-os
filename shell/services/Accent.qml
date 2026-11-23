pragma Singleton

import Quickshell
import QtQuick
import qs

// Couleur d'accent hors du shell : orbe-accent recolore les bordures de fenêtres (Hyprland),
// les applications GTK et Qt, le terminal, l'invite et btop. Lancé au démarrage, pour suivre
// les mises à jour des thèmes, et à chaque changement, un court instant après le dernier clic.
Singleton {
    id: root

    readonly property string current: Theme.accentId

    function apply() {
        Quickshell.execDetached(["orbe-accent", current]);
    }

    onCurrentChanged: debounce.restart()

    Timer {
        id: debounce

        interval: 400
        onTriggered: root.apply()
    }

    // Au démarrage, une fois shell.json lu.
    Timer {
        running: true
        interval: 3000
        onTriggered: root.apply()
    }
}
