pragma Singleton

import Quickshell
import QtQuick

// Icônes Orbe : traits fins, style monoligne, grille de 24 px.
// Chaque icône est un tracé SVG, dessiné en trait par components/Icon.qml.
Singleton {
    readonly property var paths: ({
        "search": "M10.5 4a6.5 6.5 0 1 0 0 13a6.5 6.5 0 1 0 0-13 M15.5 15.5L20 20",
        "power": "M12 3v8 M7.05 6.05a7 7 0 1 0 9.9 0",
        "restart": "M20 12a8 8 0 1 1-2.34-5.66 M20 4v5h-5",
        "sleep": "M19.5 14.5A8 8 0 0 1 9.5 4.5a8 8 0 1 0 10 10z",
        "lock": "M6 11h12v9H6z M8.5 11V8a3.5 3.5 0 0 1 7 0v3",
        "logout": "M14 4h5v16h-5 M10 8l-4 4l4 4 M6 12h10",
        "volume": "M4 9h4l5-4v14l-5-4H4z M16.5 9a4 4 0 0 1 0 6 M19 6.5a7.5 7.5 0 0 1 0 11",
        "volume-low": "M4 9h4l5-4v14l-5-4H4z M16.5 9a4 4 0 0 1 0 6",
        "volume-mute": "M4 9h4l5-4v14l-5-4H4z M17 9.5l5 5 M22 9.5l-5 5",
        "brightness": "M12 8.5a3.5 3.5 0 1 0 0 7a3.5 3.5 0 1 0 0-7 M12 2.5v2 M12 19.5v2 M2.5 12h2 M19.5 12h2 M5.3 5.3l1.4 1.4 M17.3 17.3l1.4 1.4 M5.3 18.7l1.4-1.4 M17.3 6.7l1.4-1.4",
        "capslock": "M12 4l-7 8h4v4h6v-4h4z M9 20h6",
        "bell": "M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z M10 20.5a2.2 2.2 0 0 0 4 0",
        "bell-off": "M6 16v-5a6 6 0 0 1 9-5.2 M18 11v5l1.5 2H8 M10 20.5a2.2 2.2 0 0 0 4 0 M4 4l16 16",
        "battery": "M3 8h15v8H3z M20.5 10.5v3",
        "battery-charging": "M3 8h15v8H3z M20.5 10.5v3 M11.5 9.5l-2.5 3h3l-2.5 3",
        "terminal": "M4 5h16v14H4z M7.5 9.5l3 2.5l-3 2.5 M12.5 15h4",
        "calculator": "M6 3h12v18H6z M9 7h6 M9 11h.01 M12 11h.01 M15 11h.01 M9 14.5h.01 M12 14.5h.01 M15 14.5h.01 M9 18h6",
        "emoji": "M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18 M8.5 14a4.5 4.5 0 0 0 7 0 M9 9.5h.01 M15 9.5h.01",
        "command": "M5 7l5 5l-5 5 M12 17h7",
        "file": "M6 3h8l4 4v14H6z M14 3v4h4",
        "folder": "M3 6h6l2 2h10v11H3z",
        "apps": "M4 4h7v7H4z M13 4h7v7h-7z M4 13h7v7H4z M13 13h7v7h-7z",
        "action": "M13 3L5 13h6l-1 8l8-10h-6z",
        "close": "M6 6l12 12 M18 6L6 18",
        "gamepad": "M7 8h10a4 4 0 0 1 4 4.5l-.6 3.4a2.5 2.5 0 0 1-4.3 1.2L14 15h-4l-2.1 2.1a2.5 2.5 0 0 1-4.3-1.2L3 12.5A4 4 0 0 1 7 8z M7.5 10.5v3 M6 12h3 M16 11h.01 M17.5 12.5h.01",
        "copy": "M8 8h11v12H8z M5 16V4h11",
        "check": "M5 12.5l4.5 4.5L19 7.5",
        "keyboard": "M3 7h18v10H3z M6.5 10h.01 M9.5 10h.01 M12.5 10h.01 M15.5 10h.01 M18 10h.01 M8 14h8"
    })

    function path(name) {
        return paths[name] ?? paths["apps"];
    }
}
