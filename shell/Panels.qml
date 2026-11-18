pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Ce qui est ouvert à l'écran, et les points d'entrée IPC appelés par les raccourcis Hyprland :
//   qs -c orbe ipc call launcher toggle
//   qs -c orbe ipc call session toggle
//   qs -c orbe ipc call center toggle
Singleton {
    id: root

    property bool launcherOpen: false
    property string launcherText: ""
    property bool sessionOpen: false
    property bool centerOpen: false

    // Écran où s'ouvrent les panneaux : celui qui a le focus dans Hyprland, sinon le premier.
    function isActive(screen) {
        const monitor = Hyprland.focusedMonitor;
        if (monitor && monitor.name)
            return monitor.name === screen.name;
        return screen === Quickshell.screens[0];
    }

    function openLauncher(text) {
        sessionOpen = false;
        centerOpen = false;
        launcherText = text ?? "";
        launcherOpen = true;
    }

    function toggleLauncher() {
        if (launcherOpen)
            launcherOpen = false;
        else
            openLauncher("");
    }

    function toggleSession() {
        launcherOpen = false;
        centerOpen = false;
        sessionOpen = !sessionOpen;
    }

    function toggleCenter() {
        launcherOpen = false;
        sessionOpen = false;
        centerOpen = !centerOpen;
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleLauncher();
        }
        function open(text: string): void {
            root.openLauncher(text);
        }
        function close(): void {
            root.launcherOpen = false;
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            root.toggleSession();
        }
    }

    IpcHandler {
        target: "center"

        function toggle(): void {
            root.toggleCenter();
        }
    }
}
