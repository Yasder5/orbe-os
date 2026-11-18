pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Ce qui est ouvert à l'écran, et les points d'entrée IPC appelés par les raccourcis Hyprland
// (qs -c orbe ipc call <cible> <fonction>). Un seul panneau à la fois, sauf le verrouillage.
Singleton {
    id: root

    property bool launcherOpen: false
    property string launcherText: ""
    property bool sessionOpen: false
    property bool centerOpen: false
    property bool wallpaperOpen: false
    property bool dashboardOpen: false
    property string dashboardTab: "accueil"
    property bool quickOpen: false
    property bool locked: false

    // Écran où s'ouvrent les panneaux : celui qui a le focus dans Hyprland, sinon le premier.
    function isActive(screen) {
        const monitor = Hyprland.focusedMonitor;
        if (monitor && monitor.name)
            return monitor.name === screen.name;
        return screen === Quickshell.screens[0];
    }

    function closeAll() {
        launcherOpen = false;
        sessionOpen = false;
        centerOpen = false;
        wallpaperOpen = false;
        dashboardOpen = false;
        quickOpen = false;
    }

    function openLauncher(text) {
        closeAll();
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
        const open = !sessionOpen;
        closeAll();
        sessionOpen = open;
    }

    function toggleCenter() {
        const open = !centerOpen;
        closeAll();
        centerOpen = open;
    }

    function toggleWallpaper() {
        const open = !wallpaperOpen;
        closeAll();
        wallpaperOpen = open;
    }

    function toggleDashboard(tab) {
        const open = !dashboardOpen || (tab && tab !== dashboardTab);
        closeAll();
        if (tab)
            dashboardTab = tab;
        dashboardOpen = open;
    }

    function toggleQuick() {
        const open = !quickOpen;
        closeAll();
        quickOpen = open;
    }

    function lock() {
        closeAll();
        locked = true;
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

    IpcHandler {
        target: "wallpaper"

        function picker(): void {
            root.toggleWallpaper();
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.toggleDashboard("");
        }
        function tab(name: string): void {
            root.toggleDashboard(name);
        }
    }

    IpcHandler {
        target: "quick"

        function toggle(): void {
            root.toggleQuick();
        }
    }

    // Appelé par hypridle (lock_cmd) et par Super + L.
    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}
