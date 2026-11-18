pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Luminosité de l'écran intégré (brightnessctl). Absente sur un PC de bureau.
// Les touches de luminosité appellent « qs -c orbe ipc call brightness up|down ».
Singleton {
    id: root

    property bool available: false
    property real level: 0

    signal touched

    function change(step) {
        const arg = step > 0 ? `${step}%+` : `${-step}%-`;
        setter.command = ["brightnessctl", "-m", "-c", "backlight", "-e4", "-n2", "set", arg];
        setter.running = true;
    }

    function parse(text, announce) {
        // Format -m : appareil,classe,valeur,pourcentage%,maximum
        const fields = text.trim().split("\n")[0].split(",");
        if (fields.length < 5)
            return;
        available = true;
        level = parseInt(fields[3]) / 100;
        if (announce)
            touched();
    }

    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text, false)
        }
    }

    Process {
        id: setter

        stdout: StdioCollector {
            onStreamFinished: root.parse(text, true)
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.change(5);
        }
        function down(): void {
            root.change(-5);
        }
    }
}
