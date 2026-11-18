// Logo Orbe : petite sphère de particules (points blanc cassé, quelques points accent).
// Dessinée une seule fois : aucun coût au repos.

import QtQuick
import qs

Canvas {
    id: logo

    property int particles: 46

    renderStrategy: Canvas.Cooperative
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) * 0.42;
        const cx = width / 2;
        const cy = height / 2;
        const golden = Math.PI * (1 + Math.sqrt(5));
        const yaw = 0.6, tilt = -0.42;
        let points = [];
        for (let i = 0; i < particles; i++) {
            const phi = Math.acos(1 - 2 * (i + 0.5) / particles);
            const theta = golden * (i + 0.5);
            let x = Math.cos(theta) * Math.sin(phi);
            let y = Math.sin(theta) * Math.sin(phi);
            let z = Math.cos(phi);
            // Rotation autour de Y puis de X, comme les visuels de démarrage.
            const x1 = x * Math.cos(yaw) + z * Math.sin(yaw);
            const z1 = -x * Math.sin(yaw) + z * Math.cos(yaw);
            const y2 = y * Math.cos(tilt) - z1 * Math.sin(tilt);
            const z2 = y * Math.sin(tilt) + z1 * Math.cos(tilt);
            points.push({ x: x1, y: y2, z: z2, accent: i % 4 === 0 });
        }
        points.sort((a, b) => a.z - b.z);
        for (const p of points) {
            const depth = (p.z + 1) / 2;
            ctx.globalAlpha = p.accent ? 0.45 + 0.55 * depth : 0.2 + 0.5 * depth;
            ctx.fillStyle = p.accent ? Theme.accent : Theme.text;
            const s = (p.accent ? 1.6 : 1.0) * (0.6 + 0.6 * depth);
            ctx.beginPath();
            ctx.arc(cx + p.x * r, cy + p.y * r, s, 0, 2 * Math.PI);
            ctx.fill();
        }
    }
}
