// Titre de page des réglages, avec une phrase d'explication.

import QtQuick
import qs
import qs.components

Column {
    property string title: ""
    property string subtitle: ""

    width: parent ? parent.width : 600
    spacing: Theme.space1
    bottomPadding: Theme.space4

    OText {
        text: parent.title
        font.pixelSize: Theme.textXl
        font.weight: Font.DemiBold
    }
    OText {
        width: parent.width
        visible: parent.subtitle !== ""
        text: parent.subtitle
        color: Theme.muted
        wrapMode: Text.WordWrap
    }
}
