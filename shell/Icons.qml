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
        "keyboard": "M3 7h18v10H3z M6.5 10h.01 M9.5 10h.01 M12.5 10h.01 M15.5 10h.01 M18 10h.01 M8 14h8",
        "play": "M8 5.5v13l10.5-6.5z",
        "pause": "M8 5v14 M16 5v14",
        "next": "M6 6l9 6l-9 6z M18 6v12",
        "previous": "M18 6l-9 6l9 6z M6 6v12",
        "wifi": "M2.5 9a14 14 0 0 1 19 0 M5.5 12.5a9.5 9.5 0 0 1 13 0 M8.5 16a5 5 0 0 1 7 0 M12 19.5h.01",
        "wifi-off": "M2.5 9a14 14 0 0 1 19 0 M5.5 12.5a9.5 9.5 0 0 1 13 0 M8.5 16a5 5 0 0 1 7 0 M12 19.5h.01 M4 4l16 16",
        "ethernet": "M4 14h16v6H4z M8 14v-4h8v4 M10 10V5h4v5 M7 17h.01 M10 17h.01 M14 17h.01 M17 17h.01",
        "bluetooth": "M7 7l10 10l-5 4V3l5 4L7 17",
        "bluetooth-off": "M7 7l10 10l-5 4V3l5 4L7 17 M4 4l16 16",
        "moon": "M19.5 14.5A8 8 0 0 1 9.5 4.5a8 8 0 1 0 10 10z",
        "speed": "M5 18a8 8 0 1 1 14 0 M12 14l4-5 M12 14h.01",
        "leaf": "M5 19c0-8 5-13 14-14c-1 9-6 14-14 14z M5 19l7-7",
        "cpu": "M7 7h10v10H7z M10 10h4v4h-4z M9 3v4 M15 3v4 M9 17v4 M15 17v4 M3 9h4 M3 15h4 M17 9h4 M17 15h4",
        "memory": "M3 8h18v8H3z M7 8v8 M11 8v8 M15 8v8 M6 19v-3 M18 19v-3",
        "disk": "M4 5h16v14H4z M4 14h16 M16.5 16.5h.01",
        "network": "M12 3v10 M8 9l4 4l4-4 M12 21v-4 M8 15l4-4",
        "temperature": "M10 4a2 2 0 0 1 4 0v10a4 4 0 1 1-4 0z M12 9v8",
        "gpu": "M3 7h18v10H3z M7 10h6v4H7z M16 10h2 M16 14h2 M6 17v3 M10 17v3",
        "music": "M9 18V6l11-2v12 M9 18a3 3 0 1 1-6 0a3 3 0 1 1 6 0z M20 16a3 3 0 1 1-6 0a3 3 0 1 1 6 0z",
        "home": "M4 11l8-7l8 7v9H4z M10 20v-6h4v6",
        "chart": "M4 20V10 M10 20V4 M16 20v-8 M22 20H2",
        "calendar": "M4 6h16v14H4z M4 10h16 M8 3v5 M16 3v5",
        "cloud": "M7 18a4.5 4.5 0 0 1-.5-9a6 6 0 0 1 11.5 1.5a3.75 3.75 0 0 1-.5 7.5z",
        "sun": "M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8 M12 2v2 M12 20v2 M2 12h2 M20 12h2 M4.9 4.9l1.4 1.4 M17.7 17.7l1.4 1.4 M4.9 19.1l1.4-1.4 M17.7 6.3l1.4-1.4",
        "rain": "M7 15a4.5 4.5 0 0 1-.5-9a6 6 0 0 1 11.5 1.5a3.75 3.75 0 0 1-.5 7.5z M8 18l-1 3 M12 18l-1 3 M16 18l-1 3",
        "snow": "M7 15a4.5 4.5 0 0 1-.5-9a6 6 0 0 1 11.5 1.5a3.75 3.75 0 0 1-.5 7.5z M8 19h.01 M12 20h.01 M16 19h.01",
        "storm": "M7 15a4.5 4.5 0 0 1-.5-9a6 6 0 0 1 11.5 1.5a3.75 3.75 0 0 1-.5 7.5z M13 14l-3 4h4l-3 4",
        "fog": "M4 9h16 M6 13h12 M4 17h16",
        "image": "M3 5h18v14H3z M3 16l5-5l4 4l3-3l6 6 M15.5 8.5h.01",
        "settings": "M4 7h10 M18 7h2 M4 17h4 M12 17h8 M16 5v4 M10 15v4",
        "mic": "M9 4a3 3 0 0 1 6 0v7a3 3 0 0 1-6 0z M5 11a7 7 0 0 0 14 0 M12 18v3",
        "speaker": "M6 3h12v18H6z M12 7h.01 M12 11a3.5 3.5 0 1 0 0 7a3.5 3.5 0 1 0 0-7"
    })

    function path(name) {
        return paths[name] ?? paths["apps"];
    }
}
