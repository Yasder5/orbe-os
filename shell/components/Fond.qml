// Image de fond d'écran (fond, sélecteur, accueil). Les fonds fournis par Orbe
// (/usr/share/backgrounds/orbe) sont recolorés dans la couleur d'accent choisie
// (shaders/recolor.frag) ; les images de l'utilisateur restent telles quelles.

import QtQuick
import qs

Item {
    id: root

    property string path: ""
    property size sourceSize: Qt.size(width, height)
    readonly property int status: image.status
    readonly property bool recolor: Theme.accentId !== "citron" && path.startsWith("/usr/share/backgrounds/orbe/")

    Image {
        id: image

        anchors.fill: parent
        source: root.path ? "file://" + root.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Décodée à la taille affichée : une image 4K ne coûte pas plus de mémoire qu'il ne faut.
        sourceSize: root.sourceSize
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.recolor && image.status === Image.Ready

        // Texture de l'image, recadrée comme elle (PreserveAspectCrop). L'image d'origine est
        // cachée tant que le shader la remplace ; la texture n'est refaite que si l'image change.
        property variant source: ShaderEffectSource {
            sourceItem: image
            hideSource: root.recolor
        }
        property color fromColor: Theme.wallpaperAccent
        property color toColor: Theme.accent

        fragmentShader: Qt.resolvedUrl("../shaders/recolor.frag.qsb")
    }
}
