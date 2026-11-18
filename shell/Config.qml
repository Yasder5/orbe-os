pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Réglages de l'utilisateur, lus dans ~/.config/orbe/shell.json et rechargés à chaud.
// Le fichier peut être modifié à la main ou par l'application Réglages Orbe.
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/orbe/shell.json"

    // Barre verticale à gauche ("left") ou horizontale en haut ("top").
    property alias barPosition: json.barPosition
    readonly property bool barVertical: json.barPosition !== "top"
    property alias reduceMotion: json.reduceMotion
    property alias doNotDisturb: json.doNotDisturb
    property alias clock24h: json.clock24h
    // Fond d'écran : chemin d'une image, ou « orbe-vivant » pour l'orbe animé.
    property alias wallpaper: json.wallpaper
    property alias weatherCity: json.weatherCity
    property alias nightLight: json.nightLight
    property alias nightTemperature: json.nightTemperature
    property alias sounds: json.sounds
    property alias welcomeDone: json.welcomeDone

    FileView {
        id: file

        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // Premier lancement : le fichier n'existe pas, on l'écrit avec les valeurs par défaut.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: json

            property string barPosition: "left"
            property bool reduceMotion: false
            property bool doNotDisturb: false
            property bool clock24h: true
            property string wallpaper: "/usr/share/backgrounds/orbe/orbe.png"
            property string weatherCity: "Paris"
            property bool nightLight: false
            property int nightTemperature: 4500
            property bool sounds: true
            property bool welcomeDone: false
        }
    }
}
