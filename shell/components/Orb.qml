// Orbe de particules animé, dessiné par le GPU (shaders/orb.frag) : sphère de points blanc cassé
// translucides, environ 10 % de points accent plus gros, rotation lente.
// Le processeur ne fait qu'avancer un angle à chaque image ; l'animation s'arrête quand l'orbe
// est caché, quand les animations sont réduites, ou quand « running » est faux.

import QtQuick
import qs

ShaderEffect {
    id: orb

    property int particles: 420
    // Vitesse de rotation, en radians par seconde.
    property real speed: 0.12
    // Images par seconde au plus (30 suffisent pour un fond d'écran, et économisent l'énergie).
    property int maxFps: 60
    property bool running: visible && !Theme.reduceMotion
    // Centre et rayon de l'orbe dans l'élément (par défaut : centré, presque tout l'espace).
    property point orbCenter: Qt.point(width / 2, height / 2)
    property real orbRadius: Math.min(width, height) * 0.46
    property real dotSize: Math.max(1.1, orbRadius / 160)
    property real halo: 0
    property color baseColor: Theme.text
    property color accentColor: Theme.accent
    property color background: Theme.transparent

    // Uniformes lus par le shader
    readonly property size itemSize: Qt.size(width, height)
    property real yaw: 0.6
    readonly property real tilt: -0.42
    readonly property real count: particles

    fragmentShader: Qt.resolvedUrl("../shaders/orb.frag.qsb")
    blending: true

    // Une image toutes les 1/maxFps secondes : l'orbe n'est redessiné que quand l'angle change,
    // pas à chaque image de l'écran (144 Hz et plus sur un écran de jeu).
    Timer {
        property double last: 0

        interval: Math.round(1000 / Math.max(1, orb.maxFps))
        repeat: true
        running: orb.running
        onRunningChanged: last = 0
        onTriggered: {
            const now = Date.now();
            const dt = last > 0 ? (now - last) / 1000 : interval / 1000;
            last = now;
            orb.yaw = (orb.yaw + orb.speed * Math.min(dt, 0.25)) % (2 * Math.PI);
        }
    }
}
