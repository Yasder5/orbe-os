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

    FrameAnimation {
        property real pending: 0

        running: orb.running
        onTriggered: {
            pending += frameTime;
            if (pending >= 1 / orb.maxFps) {
                orb.yaw = (orb.yaw + orb.speed * pending) % (2 * Math.PI);
                pending = 0;
            }
        }
    }
}
