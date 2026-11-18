pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs

// Actions de session : mode jeu, verrouiller, se déconnecter, veille, redémarrer, éteindre.
// Déconnexion, redémarrage et arrêt passent par hyprshutdown, qui ferme d'abord les applications
// proprement (elles peuvent proposer d'enregistrer).
Singleton {
    id: root

    readonly property var actions: [
        { id: "game", label: "Mode jeu", icon: "gamepad", danger: false },
        { id: "lock", label: "Verrouiller", icon: "lock", danger: false },
        { id: "logout", label: "Se déconnecter", icon: "logout", danger: false },
        { id: "suspend", label: "Mettre en veille", icon: "sleep", danger: false },
        { id: "reboot", label: "Redémarrer", icon: "restart", danger: false },
        { id: "poweroff", label: "Éteindre", icon: "power", danger: true }
    ]

    function run(action) {
        switch (action) {
        case "game":
            Panels.sessionOpen = false;
            Quickshell.execDetached(["orbe-switch-session", "jeu"]);
            break;
        case "lock":
            Panels.lock();
            break;
        case "logout":
            shutdown("Déconnexion", "");
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "reboot":
            shutdown("Redémarrage", "systemctl reboot");
            break;
        case "poweroff":
            shutdown("Arrêt", "systemctl poweroff");
            break;
        }
    }

    // Quitte Hyprland avec hyprshutdown, puis lance la commande donnée. Sans hyprshutdown
    // (aperçu, autre compositeur), la commande est lancée directement.
    function shutdown(title, then) {
        Panels.sessionOpen = false;
        const exit = Hyprland.usingLua ? "hyprctl dispatch 'hl.dsp.exit()'" : "hyprctl dispatch exit";
        const fallback = then || exit;
        const args = then ? ` -p '${then}'` : "";
        Quickshell.execDetached(["sh", "-c", `command -v hyprshutdown >/dev/null && hyprshutdown -t '${title}'${args} || ${fallback}`]);
    }
}
