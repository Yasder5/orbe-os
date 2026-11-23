pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs

// Actions de session : mode jeu, verrouiller, se déconnecter, veille, redémarrer, éteindre.
// Déconnexion, redémarrage et arrêt passent par hyprshutdown, qui ferme d'abord les applications
// proprement (elles peuvent proposer d'enregistrer).
Singleton {
    id: root

    // Entrée Windows du menu de démarrage (double démarrage), notée par orbe-windows --scan.
    property string windowsEntry: ""
    readonly property int openWindows: Hyprland.toplevels.values.length

    readonly property var actions: [
        { id: "game", label: "Mode jeu", icon: "gamepad", danger: false },
        { id: "lock", label: "Verrouiller", icon: "lock", danger: false },
        { id: "logout", label: "Se déconnecter", icon: "logout", danger: false },
        { id: "suspend", label: "Mettre en veille", icon: "sleep", danger: false },
        { id: "reboot", label: "Redémarrer", icon: "restart", danger: false }
    ].concat(windowsEntry ? [{ id: "windows", label: "Windows", icon: "windows", danger: false }] : [])
     .concat([{ id: "poweroff", label: "Éteindre", icon: "power", danger: true }])

    FileView {
        path: "/var/lib/orbe/windows"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.windowsEntry = text().trim()
    }

    // Passe en mode jeu tout de suite, ou demande confirmation si des fenêtres sont ouvertes
    // (elles seront fermées ; celles qui ont du travail non enregistré le proposent).
    function game(confirmed) {
        Panels.sessionOpen = false;
        if (!confirmed && openWindows > 0) {
            Panels.closeAll();
            Panels.gameConfirmOpen = true;
            return;
        }
        Panels.gameConfirmOpen = false;
        Quickshell.execDetached(["orbe-switch-session", "jeu"]);
    }

    function run(action) {
        switch (action) {
        case "game":
            game(false);
            break;
        case "windows":
            Panels.sessionOpen = false;
            Quickshell.execDetached(["sh", "-c", "pkexec orbe-windows --reboot"]);
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
