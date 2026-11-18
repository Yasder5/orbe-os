// Orbe de particules animé : sphère de points blanc cassé translucides, environ 10 % de points
// accent plus gros, qui tourne lentement. Même style que les visuels de démarrage.
// L'animation s'arrête quand l'orbe est caché ou si les animations sont réduites.

import QtQuick
import qs

Canvas {
    id: orb

    property int particles: 420
    property real speed: 0.12           // tours par minute environ x 10
    property bool running: visible && !Theme.reduceMotion
    property real yaw: 0.6
    readonly property real tilt: -0.42
    property var points: []

    renderStrategy: Canvas.Cooperative

    function build() {
        const golden = Math.PI * (1 + Math.sqrt(5));
        let seed = 7;
        const random = () => {
            seed = (seed * 16807) % 2147483647;
            return seed / 2147483647;
        };
        const list = [];
        for (let i = 0; i < particles; i++) {
            const phi = Math.acos(1 - 2 * (i + 0.5) / particles);
            const theta = golden * (i + 0.5);
            list.push({
                x: Math.cos(theta) * Math.sin(phi) + (random() - 0.5) * 0.04,
                y: Math.sin(theta) * Math.sin(phi) + (random() - 0.5) * 0.04,
                z: Math.cos(phi) + (random() - 0.5) * 0.04,
                accent: random() < 0.1
            });
        }
        points = list;
    }

    Component.onCompleted: build()
    onParticlesChanged: build()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onYawChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) * 0.46;
        const cx = width / 2, cy = height / 2;
        const sinY = Math.sin(yaw), cosY = Math.cos(yaw);
        const sinT = Math.sin(tilt), cosT = Math.cos(tilt);
        const projected = points.map(p => {
            const x1 = p.x * cosY + p.z * sinY;
            const z1 = -p.x * sinY + p.z * cosY;
            return { x: x1, y: p.y * cosT - z1 * sinT, z: p.y * sinT + z1 * cosT, accent: p.accent };
        });
        projected.sort((a, b) => a.z - b.z);
        const dot = Math.max(1, r / 160);
        for (const p of projected) {
            const depth = (p.z + 1) / 2;
            ctx.globalAlpha = p.accent ? 0.32 + 0.6 * depth : 0.08 + 0.32 * depth;
            ctx.fillStyle = p.accent ? Theme.accent : Theme.text;
            const s = dot * (p.accent ? 2.0 * (0.55 + 0.45 * depth) : 0.7 + 0.3 * depth);
            ctx.beginPath();
            ctx.arc(cx + p.x * r, cy + p.y * r, s, 0, 2 * Math.PI);
            ctx.fill();
        }
    }

    // Une rotation douce, environ 30 images par seconde, seulement quand l'orbe est visible.
    Timer {
        interval: 33
        repeat: true
        running: orb.running
        onTriggered: orb.yaw += orb.speed * 0.033
    }
}
