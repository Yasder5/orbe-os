// Fond d'écran de chaque écran : une image, ou l'orbe animé (« orbe-vivant »).
// L'orbe animé tourne à 30 images par seconde au plus, et se met en pause sur batterie,
// quand une fenêtre est en plein écran sur cet écran (jeux, vidéos) ou si les animations
// sont réduites.

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import qs
import qs.components

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool live: Config.wallpaper === "orbe-vivant"
            readonly property var monitor: Hyprland.monitorFor(modelData)
            readonly property bool fullscreenApp: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.hasFullscreen : false

            screen: modelData
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.bg
            WlrLayershell.layer: WlrLayer.Background
            // Hors de l'espace « orbe-* » : pas de flou derrière le fond d'écran.
            WlrLayershell.namespace: "wallpaper-orbe"

            Image {
                id: image

                anchors.fill: parent
                visible: !win.live
                source: win.live || !Config.wallpaper ? "" : "file://" + Config.wallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                // Décodée à la taille de l'écran : une image 4K ne coûte pas plus de mémoire qu'il ne faut.
                sourceSize: Qt.size(win.width, win.height)
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durSlow
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.curve
                    }
                }
            }

            Orb {
                anchors.fill: parent
                visible: win.live
                running: visible && !Theme.reduceMotion && !UPower.onBattery && !Panels.anyFullscreen
                maxFps: 30
                particles: 1100
                speed: 0.05
                background: Theme.bg
                halo: 0.05
                orbCenter: Qt.point(width * 0.74, height * 0.5)
                orbRadius: height * 0.4
                dotSize: Math.max(1.2, height / 460)
            }
        }
    }
}
