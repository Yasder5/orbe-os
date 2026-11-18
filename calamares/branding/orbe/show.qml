/* Diaporama de l'installation : ce qu'Orbe OS propose, pendant la copie du système. */
import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation

    property var slides: [
        { title: "Bienvenue dans Orbe OS", text: "Un système Arch pensé pour jouer et travailler : bureau Orbe, mode jeu à la manette, tout aux mêmes couleurs." },
        { title: "Le bureau Orbe", text: "Super ouvre le lanceur. Super + D pour le tableau de bord, Super + A pour les réglages rapides, Super + Échap pour le menu de session." },
        { title: "Le mode jeu", text: "Super + G, ou le bouton manette de la barre : Steam en plein écran, comme sur SteamOS. « Revenir au bureau » dans Steam pour repartir." },
        { title: "Mises à jour sereines", text: "Sur btrfs, un instantané est pris avant et après chaque mise à jour. En cas de souci, il se choisit au démarrage." }
    ]

    // Fond de toute la zone du diaporama (les diapositives n'en couvrent que le centre).
    Rectangle {
        anchors.fill: parent
        z: -1
        color: "#0a0a0a"
    }

    Timer {
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Repeater {
        model: presentation.slides

        Slide {
            required property var modelData

            Rectangle {
                anchors.fill: parent
                color: "#0a0a0a"
            }

            Image {
                source: "orb.png"
                width: Math.min(parent.width, parent.height) * 0.55
                height: width
                anchors.right: parent.right
                anchors.rightMargin: -width * 0.12
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                opacity: 0.9
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.07
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.5
                spacing: 16

                Text {
                    width: parent.width
                    text: modelData.title
                    color: "#f5f5f0"
                    font.family: "Archivo"
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }
                Rectangle {
                    width: 40
                    height: 3
                    radius: 2
                    color: "#d3fd50"
                }
                Text {
                    width: parent.width
                    text: modelData.text
                    color: "#8f8f8a"
                    font.family: "Archivo"
                    font.pixelSize: 17
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    function onActivate() { }
    function onLeave() { }
}
