pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
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
    property bool welcomeOpen: false
    property bool settingsOpen: false
    property bool helpOpen: false
    // Confirmation du passage en mode jeu quand des fenêtres sont ouvertes.
    property bool gameConfirmOpen: false
    // Enregistrement en cours (orbe-record) : « video », « replay » ou « off ».
    property string recordState: "off"
    // Une fenêtre en plein écran sur un écran : jeu, vidéo. Coupe les bulles et l'orbe vivant.
    readonly property bool anyFullscreen: Hyprland.monitors.values.some(m => m.activeWorkspace && m.activeWorkspace.hasFullscreen)
    property string settingsPage: ""
    property int welcomeStep: 0
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
        welcomeOpen = false;
        helpOpen = false;
        gameConfirmOpen = false;
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
        // Super + G : mode jeu, avec confirmation si des fenêtres sont ouvertes.
        function game(): void {
            Session.run("game");
        }
    }

    // orbe-record annonce l'état de l'enregistrement : indicateur fixe dans la barre.
    IpcHandler {
        target: "record"

        function state(value: string): void {
            root.recordState = value;
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

    IpcHandler {
        target: "help"

        function toggle(): void {
            const open = !root.helpOpen;
            root.closeAll();
            root.helpOpen = open;
        }
    }

    IpcHandler {
        target: "welcome"

        function open(): void {
            root.closeAll();
            root.welcomeStep = 0;
            root.welcomeOpen = true;
        }
        function close(): void {
            root.welcomeOpen = false;
        }
        // Ouvre directement une étape (0 à 4) : aperçus et tests.
        function step(index: int): void {
            root.closeAll();
            root.welcomeStep = index;
            root.welcomeOpen = true;
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
