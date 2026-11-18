pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs

// Réglages de Hyprland faits dans « Réglages Orbe » : clavier, souris, pavé tactile, écrans.
// Gardés dans ~/.config/orbe/reglages.json (relus à chaud) et traduits en Lua dans
// ~/.config/orbe/hyprland.lua, chargé par la configuration Hyprland d'Orbe.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/orbe"
    property alias kbLayout: json.kbLayout
    property alias kbVariant: json.kbVariant
    property alias sensitivity: json.sensitivity
    property alias accelFlat: json.accelFlat
    property alias naturalScroll: json.naturalScroll
    property alias tapToClick: json.tapToClick
    property alias monitors: json.monitors
    // Session ouverte au démarrage : « derniere », « bureau » ou « jeu » (lu par orbe-session).
    property alias startSession: json.startSession

    // Écrans connectés, lus dans hyprctl monitors -j : nom, modèle, mode actuel, modes possibles.
    property var outputs: []

    function refreshOutputs() {
        monitorsProc.running = true;
    }

    function luaString(s) {
        return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
    }

    // Écrit le fichier Lua puis recharge Hyprland.
    function apply() {
        const lines = [
            "-- Généré par Réglages Orbe à partir de ~/.config/orbe/reglages.json : modifie plutôt l'application.",
            "hl.config({",
            "    input = {",
            "        kb_layout = " + luaString(kbLayout) + ",",
            "        kb_variant = " + luaString(kbVariant) + ",",
            "        sensitivity = " + Number(sensitivity).toFixed(2) + ",",
            "        accel_profile = " + luaString(accelFlat ? "flat" : "adaptive") + ",",
            "        touchpad = {",
            "            natural_scroll = " + (naturalScroll ? "true" : "false") + ",",
            "            tap_to_click = " + (tapToClick ? "true" : "false") + ",",
            "        },",
            "    },",
            "})"
        ];
        for (const name in monitors) {
            const m = monitors[name];
            lines.push("hl.monitor({ output = " + luaString(name) + ", mode = " + luaString(m.mode || "preferred")
                       + ", position = " + luaString(m.position || "auto") + ", scale = " + luaString(String(m.scale || "auto")) + " })");
        }
        lua.setText(lines.join("\n") + "\n");
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprctl reload >/dev/null"]);
    }

    function setMonitor(name, key, value) {
        const all = Object.assign({}, monitors);
        all[name] = Object.assign({}, all[name] || {}, { [key]: value });
        monitors = all;
        apply();
    }

    FileView {
        id: lua

        path: root.dir + "/hyprland.lua"
        atomicWrites: true
    }

    FileView {
        path: root.dir + "/reglages.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: json

            property string kbLayout: "fr"
            property string kbVariant: ""
            property real sensitivity: 0
            property bool accelFlat: true
            property bool naturalScroll: true
            property bool tapToClick: true
            property var monitors: ({})
            property string startSession: "derniere"
        }
    }

    // Choix de la session au démarrage, lu par orbe-session (fichier texte d'une ligne).
    FileView {
        id: startFile

        path: root.dir + "/demarrage"
    }
    onStartSessionChanged: startFile.setText(startSession === "derniere" ? "" : startSession + "\n")

    Process {
        id: monitorsProc

        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.outputs = JSON.parse(text).map(m => ({
                        name: m.name,
                        model: ((m.make || "") + " " + (m.model || "")).trim() || m.name,
                        mode: m.width + "x" + m.height + "@" + Number(m.refreshRate).toFixed(2),
                        scale: m.scale,
                        x: m.x,
                        y: m.y,
                        modes: (m.availableModes || []).map(s => s.replace(/Hz$/, ""))
                    }));
                } catch (e) {
                    root.outputs = [];
                }
            }
        }
    }
}
