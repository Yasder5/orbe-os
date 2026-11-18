pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// État du verrouillage majuscules, lu sur les voyants du clavier après chaque appui.
// Hyprland appelle « qs -c orbe ipc call keyboard capslock » sur la touche Verr. Maj.
Singleton {
    id: root

    property bool capsLock: false

    signal touched

    function refresh() {
        reader.running = true;
    }

    Process {
        id: reader

        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | sort -r | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.capsLock = parseInt(text) > 0;
                root.touched();
            }
        }
    }

    // Le voyant change un instant après l'appui.
    Timer {
        id: delay

        interval: 120
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "keyboard"

        function capslock(): void {
            delay.restart();
        }
    }
}
