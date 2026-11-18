// Texte Orbe : Archivo, couleur text, taille moyenne par défaut.

import QtQuick
import qs

Text {
    property bool mono: false

    color: Theme.text
    font.family: mono ? Theme.fontMono : Theme.fontSans
    font.pixelSize: Theme.textM
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
