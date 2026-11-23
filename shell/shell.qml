// Orbe Shell : point d'entrée, lancé par « qs -c orbe » au démarrage de Hyprland.

import Quickshell
import QtQuick
import qs
import qs.bar
import qs.dashboard
import qs.launcher
import qs.lock
import qs.notifications
import qs.osd
import qs.quicksettings
import qs.services
import qs.session
import qs.wallpaper
import qs.welcome
import qs.settings
import qs.help

ShellRoot {
    Wallpaper {}
    Bar {}
    Launcher {}
    Popups {}
    Center {}
    Osd {}
    SessionMenu {}
    GameConfirm {}
    Picker {}
    QuickSettings {}
    Dashboard {}
    Lock {}
    Welcome {}
    Settings {}
    Help {}

    // Les services qui répondent aux raccourcis par IPC, ou qui appliquent un réglage au
    // démarrage, doivent exister dès le lancement.
    Component.onCompleted: [Brightness.available, Keyboard.capsLock, Notifs.count, Panels.launcherOpen, Night.enabled, Weather.city, Reglages.kbLayout, Accent.current]
}
