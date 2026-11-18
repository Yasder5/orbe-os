// Icône de la fenêtre active (via le protocole Wayland des fenêtres de premier niveau).

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs

Item {
    id: root

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property var entry: toplevel ? DesktopEntries.heuristicLookup(toplevel.appId) : null
    // Fenêtres du shell lui-même (Réglages Orbe) : logo Orbe.
    readonly property string iconSource: toplevel && toplevel.appId === "org.quickshell" ? Quickshell.iconPath("orbe", "application-x-executable")
                                         : entry ? Quickshell.iconPath(entry.icon, "application-x-executable") : ""

    implicitWidth: Theme.barSize - Theme.space3
    implicitHeight: Theme.barSize - Theme.space3
    visible: toplevel !== null && iconSource !== ""

    IconImage {
        anchors.centerIn: parent
        implicitSize: 22
        source: root.iconSource
        asynchronous: true
    }
}
