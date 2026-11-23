// Petit graphe sobre tracé en accent : ligne et aire légère. Redessiné à chaque nouvelle valeur.

import QtQuick
import qs

Canvas {
    id: root

    property var values: []
    // Valeur maximale de l'échelle (1 pour un pourcentage, automatique si 0).
    property real maximum: 1
    property int capacity: 60

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    // Redessiné quand la couleur d'accent change (Réglages, Apparence).
    readonly property color accentColor: Theme.accent
    onAccentColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (values.length < 2)
            return;
        const top = maximum > 0 ? maximum : Math.max(1, ...values) * 1.15;
        const stepX = width / (capacity - 1);
        const offset = capacity - values.length;
        ctx.beginPath();
        values.forEach((v, i) => {
            const x = (offset + i) * stepX;
            const y = height - 1 - (height - 2) * Math.min(1, v / top);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        });
        ctx.strokeStyle = Theme.accent;
        ctx.lineWidth = 1.5;
        ctx.stroke();
        ctx.lineTo(width, height);
        ctx.lineTo(offset * stepX, height);
        ctx.closePath();
        ctx.fillStyle = Theme.glow;
        ctx.fill();
    }
}
