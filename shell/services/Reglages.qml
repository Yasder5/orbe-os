pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs

// Réglages faits dans « Réglages Orbe », gardés dans ~/.config/orbe/reglages.json (relus à chaud)
// et traduits pour chaque outil :
//   - clavier, souris, pavé tactile, écrans : ~/.config/orbe/hyprland.lua (Lua de Hyprland) ;
//   - mode jeu : ~/.config/orbe/jeu.conf (lu par orbe-game-session et orbe-steam-fond) ;
//   - énergie : ~/.config/orbe/hypridle.conf (lu par orbe-idle) ;
//   - session au démarrage : ~/.config/orbe/demarrage (lu par orbe-session).
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
    // Mode jeu : écran de gamescope (vide : le premier), profil « performances », moteur
    // (« gamescope » ou « secours »), Steam en arrière-plan sur le bureau.
    property alias jeuEcran: json.jeuEcran
    property alias jeuPerf: json.jeuPerf
    property alias jeuMoteur: json.jeuMoteur
    property alias steamFond: json.steamFond
    // Énergie, en minutes (0 : jamais).
    property alias ecranEteint: json.ecranEteint
    property alias veille: json.veille
    property alias verrouillage: json.verrouillage

    // Disposition du clavier du système (choisie à l'installation), utilisée tant que
    // l'utilisateur n'en a pas choisi une autre ici (kbLayout vide).
    property string systemLayout: "fr"
    property string systemVariant: ""
    readonly property string currentLayout: kbLayout || systemLayout

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
            "    input = {"
        ];
        // Disposition écrite seulement si elle a été choisie ici : sinon celle du système.
        if (kbLayout)
            lines.push("        kb_layout = " + luaString(kbLayout) + ",", "        kb_variant = " + luaString(kbVariant) + ",");
        lines.push(
            "        sensitivity = " + Number(sensitivity).toFixed(2) + ",",
            "        accel_profile = " + luaString(accelFlat ? "flat" : "adaptive") + ",",
            "        touchpad = {",
            "            natural_scroll = " + (naturalScroll ? "true" : "false") + ",",
            "            tap_to_click = " + (tapToClick ? "true" : "false") + ",",
            "        },",
            "    },",
            "})"
        );
        for (const name in monitors) {
            const m = monitors[name];
            lines.push("hl.monitor({ output = " + luaString(name) + ", mode = " + luaString(m.mode || "preferred")
                       + ", position = " + luaString(m.position || "auto") + ", scale = " + luaString(String(m.scale || "auto")) + " })");
        }
        lua.setText(lines.join("\n") + "\n");
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprctl reload >/dev/null"]);
    }

    // Mode jeu : fichier de variables pour les scripts (orbe-game-session, orbe-steam-fond).
    function applyJeu() {
        jeuFile.setText([
            "# Généré par Réglages Orbe (Mode jeu) : modifie plutôt l'application.",
            "ORBE_JEU_ECRAN=" + JSON.stringify(jeuEcran),
            "ORBE_JEU_PERF=" + (jeuPerf ? 1 : 0),
            "ORBE_JEU_MOTEUR=" + (jeuMoteur === "secours" ? "secours" : "gamescope"),
            "ORBE_STEAM_FOND=" + (steamFond ? 1 : 0)
        ].join("\n") + "\n");
    }

    // Énergie : configuration de hypridle, puis relance de hypridle.
    function applyEnergie() {
        const lines = [
            "# Généré par Réglages Orbe (Énergie) : modifie plutôt l'application.",
            "general {",
            "    lock_cmd = qs -c orbe ipc call lock lock",
            "    before_sleep_cmd = loginctl lock-session",
            "    after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'",
            "}"
        ];
        if (verrouillage > 0)
            lines.push("listener {", "    timeout = " + verrouillage * 60, "    on-timeout = loginctl lock-session", "}");
        if (ecranEteint > 0)
            lines.push("listener {", "    timeout = " + ecranEteint * 60,
                       "    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'",
                       "    on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'", "}");
        if (veille > 0)
            lines.push("listener {", "    timeout = " + veille * 60, "    on-timeout = orbe-suspend-check && systemctl suspend", "}");
        idleFile.setText(lines.join("\n") + "\n");
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; orbe-idle --relancer"]);
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
        id: reglagesFile

        path: root.dir + "/reglages.json"
        watchChanges: true
        // Un fichier absent au lancement n'est pas surveillé : une fois qu'il est créé, on relance
        // la surveillance, sinon ses modifications faites à la main ne seraient plus suivies.
        property Timer rearm: Timer {
            interval: 1000
            onTriggered: {
                reglagesFile.watchChanges = false;
                reglagesFile.watchChanges = true;
            }
        }
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter();
                rearm.start();
            }
        }

        JsonAdapter {
            id: json

            property string kbLayout: ""
            property string kbVariant: ""
            property real sensitivity: 0
            property bool accelFlat: true
            property bool naturalScroll: true
            property bool tapToClick: true
            property var monitors: ({})
            property string startSession: "derniere"
            property string jeuEcran: ""
            property bool jeuPerf: true
            property string jeuMoteur: "gamescope"
            property bool steamFond: false
            property int ecranEteint: 11
            property int veille: 60
            property int verrouillage: 10
        }
    }

    FileView {
        id: jeuFile

        path: root.dir + "/jeu.conf"
        atomicWrites: true
    }

    FileView {
        id: idleFile

        path: root.dir + "/hypridle.conf"
        atomicWrites: true
    }

    // Disposition du clavier du système (Calamares ou localectl l'écrivent ici).
    FileView {
        path: "/etc/X11/xorg.conf.d/00-keyboard.conf"
        onLoaded: {
            const t = text();
            const l = t.match(/"XkbLayout"\s+"([^",]+)/);
            const v = t.match(/"XkbVariant"\s+"([^",]*)/);
            if (l)
                root.systemLayout = l[1];
            if (v)
                root.systemVariant = v[1];
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
