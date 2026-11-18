pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Actions de session : verrouiller, se déconnecter, veille, redémarrer, éteindre.
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock", label: "Verrouiller", icon: "lock", danger: false },
        { id: "logout", label: "Se déconnecter", icon: "logout", danger: false },
        { id: "suspend", label: "Mettre en veille", icon: "sleep", danger: false },
        { id: "reboot", label: "Redémarrer", icon: "restart", danger: false },
        { id: "poweroff", label: "Éteindre", icon: "power", danger: true }
    ]

    function run(action) {
        switch (action) {
        case "lock":
            Quickshell.execDetached(["loginctl", "lock-session"]);
            break;
        case "logout":
            Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit");
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }
}
