// Aide des raccourcis : tous les raccourcis d'Orbe OS sur un écran (Super + Maj + : sur un
// clavier AZERTY, Super + / en QWERTY). Échap ou un clic pour fermer.
// Liste tenue en accord avec packages/orbe-desktop/binds.lua et docs/raccourcis.md.

import Quickshell
import Quickshell.Wayland
import QtQuick
import qs
import qs.components

Scope {
    id: root

    readonly property var sections: [
        { title: "Applications", keys: [
            ["Super", "Lanceur et ses préfixes > = : / ~ # !"],
            ["Super + Entrée", "Terminal"], ["Super + E", "Fichiers"], ["Super + V", "Historique du presse-papiers"],
            ["Super + D", "Tableau de bord"], ["Super + A", "Réglages rapides"], ["Super + W", "Fond d'écran"],
            ["Super + G", "Mode jeu"], ["Super + Maj + :", "Cette aide"]
        ] },
        { title: "Fenêtres", keys: [
            ["Super + Q", "Fermer"], ["Super + F", "Plein écran"], ["Super + Espace", "Flottante ou en mosaïque"],
            ["Super + J", "Sens de la découpe"], ["Super + flèches", "Fenêtre voisine"],
            ["Super + clic gauche", "Déplacer"], ["Super + clic droit", "Redimensionner"]
        ] },
        { title: "Espaces de travail", keys: [
            ["Super + 1 à 9", "Aller à l'espace (rangée du haut)"], ["Super + Maj + 1 à 9", "Y envoyer la fenêtre"],
            ["Super + molette", "Espace suivant ou précédent"], ["Trois doigts", "Pareil, au pavé tactile"]
        ] },
        { title: "Système", keys: [
            ["Impr.", "Capture de l'écran"], ["Super + Maj + S", "Capture d'une zone"], ["Super + Impr.", "Zone à annoter"],
            ["Super + Maj + R", "Enregistrer l'écran"], ["Super + Maj + G", "Garder les 30 dernières secondes"],
            ["Super + L", "Verrouiller"], ["Super + Échap", "Menu de session"],
            ["Super + N", "Notifications"], ["Touches multimédia", "Volume, luminosité, lecture"],
            ["Super + Maj + M", "Quitter la session (secours)"]
        ] }
    ]

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: Panels.helpOpen && Panels.isActive(modelData)
            property real progress: open ? 1 : 0

            screen: modelData
            visible: open || progress > 0
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "orbe-help"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            onOpenChanged: if (open) content.forceActiveFocus()

            Behavior on progress {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: win.progress
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Panels.helpOpen = false
            }

            Item {
                id: content

                anchors.fill: parent
                opacity: win.progress
                focus: win.open
                Keys.onEscapePressed: Panels.helpOpen = false

                Rectangle {
                    anchors.centerIn: parent
                    width: grid.implicitWidth + Theme.space6 * 2
                    height: grid.implicitHeight + heading.implicitHeight + Theme.space6 * 2 + Theme.space4
                    radius: Theme.radiusL
                    color: Theme.panel
                    border.width: 1
                    border.color: Theme.line
                    scale: 0.97 + 0.03 * win.progress

                    OText {
                        id: heading

                        x: Theme.space6
                        y: Theme.space6
                        text: "Raccourcis clavier"
                        font.pixelSize: Theme.textXl
                        font.weight: Font.DemiBold
                    }

                    Grid {
                        id: grid

                        anchors.top: heading.bottom
                        anchors.topMargin: Theme.space4
                        x: Theme.space6
                        columns: 2
                        columnSpacing: Theme.space6
                        rowSpacing: Theme.space5

                        Repeater {
                            model: root.sections

                            Column {
                                id: section

                                required property var modelData

                                width: 560
                                spacing: Theme.space2

                                OText {
                                    text: section.modelData.title
                                    color: Theme.accent
                                    font.pixelSize: Theme.textS
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1
                                }
                                Repeater {
                                    model: section.modelData.keys

                                    Row {
                                        required property var modelData

                                        spacing: Theme.space3

                                        Rectangle {
                                            width: 176
                                            height: 26
                                            radius: Theme.radiusS
                                            color: Theme.surface2
                                            border.width: 1
                                            border.color: Theme.line

                                            OText {
                                                anchors.centerIn: parent
                                                text: modelData[0]
                                                mono: true
                                                font.pixelSize: Theme.textXs
                                            }
                                        }
                                        OText {
                                            width: 370
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData[1]
                                            color: Theme.muted
                                            font.pixelSize: Theme.textS
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
