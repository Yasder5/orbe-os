// Orbe Shell : point d'entrée, lancé par « qs -c orbe » au démarrage de Hyprland.

import Quickshell
import QtQuick
import qs
import qs.bar
import qs.launcher
import qs.notifications
import qs.osd
import qs.services
import qs.session

ShellRoot {
    Bar {}
    Launcher {}
    Popups {}
    Center {}
    Osd {}
    SessionMenu {}

    // Les services qui répondent aux raccourcis par IPC doivent exister dès le démarrage.
    Component.onCompleted: [Brightness.available, Keyboard.capsLock, Notifs.count, Panels.launcherOpen]
}
