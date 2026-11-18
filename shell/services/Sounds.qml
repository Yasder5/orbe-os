pragma Singleton

import Quickshell
import QtQuick
import qs

// Sons système d'Orbe (thème freedesktop « orbe », paquet orbe-themes), joués par PipeWire.
// Coupés par le réglage « sounds » de ~/.config/orbe/shell.json.
Singleton {
    id: root

    readonly property string dir: "/usr/share/sounds/orbe/stereo/"
    property double last: 0

    function play(name) {
        if (!Config.sounds)
            return;
        // Pas plus d'un son toutes les 90 ms (molette sur le volume, rafale de notifications).
        const now = Date.now();
        if (now - last < 90)
            return;
        last = now;
        Quickshell.execDetached(["pw-play", "--volume", "0.6", dir + name + ".wav"]);
    }
}
