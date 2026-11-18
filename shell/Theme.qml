pragma Singleton

import Quickshell
import QtQuick

// Jetons de l'identité Orbe (docs/PROMPT.md, section 1).
// Seul fichier du shell où une couleur, une police, un rayon ou une durée peut être écrit en dur.
Singleton {
    id: theme

    // Couleurs
    readonly property color bg: "#0a0a0a"
    readonly property color bg2: "#0d0d0c"
    readonly property color surface: "#121212"
    readonly property color surface2: "#1a1a19"
    readonly property color line: "#262624"
    readonly property color line2: "#3a3a37"
    readonly property color text: "#f5f5f0"
    readonly property color muted: "#8f8f8a"
    readonly property color accent: "#d3fd50"
    readonly property color accentHover: "#e1ff80"
    readonly property color accentActive: "#bde83a"
    readonly property color textOnAccent: "#0a0a0a"
    readonly property color danger: "#ff6b5a"
    readonly property color glow: Qt.rgba(211 / 255, 253 / 255, 80 / 255, 0.16)
    readonly property color focusGlow: Qt.rgba(211 / 255, 253 / 255, 80 / 255, 0.28)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)
    readonly property color scrim: Qt.rgba(10 / 255, 10 / 255, 10 / 255, 0.82)
    readonly property color panel: Qt.rgba(18 / 255, 18 / 255, 18 / 255, 0.94)
    readonly property color transparent: "transparent"

    // Polices
    readonly property string fontSans: "Archivo"
    readonly property string fontMono: "JetBrains Mono"
    readonly property int textXs: 11
    readonly property int textS: 13
    readonly property int textM: 15
    readonly property int textL: 18
    readonly property int textXl: 28
    readonly property int textHuge: 72

    // Rayons : petit, moyen, grand. Pas d'interface toute ronde.
    readonly property int radiusS: 4
    readonly property int radiusM: 6
    readonly property int radiusL: 8

    // Espacements
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 24
    readonly property int space6: 32

    // Animations : 150, 300 et 600 ms, courbe cubic-bezier(.2,.8,.2,1).
    // Le réglage « réduire les animations » (Config.reduceMotion) les ramène à zéro.
    readonly property bool reduceMotion: Config.reduceMotion
    readonly property int durFast: reduceMotion ? 0 : 150
    readonly property int durMed: reduceMotion ? 0 : 300
    readonly property int durSlow: reduceMotion ? 0 : 600
    readonly property var curve: [0.2, 0.8, 0.2, 1, 1, 1]

    // Dimensions du shell
    readonly property int barSize: 52
    readonly property int gap: 14
    readonly property int iconSize: 20
}
