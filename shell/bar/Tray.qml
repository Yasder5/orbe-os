// Zone de notifications système (icônes des applications en arrière-plan).
// Clic gauche : action principale. Clic droit : menu de l'application.

import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs

Grid {
    id: root

    property bool vertical: true
    required property var window

    columns: vertical ? 1 : Math.max(1, repeater.count)
    spacing: Theme.space1
    visible: repeater.count > 0

    Repeater {
        id: repeater

        model: SystemTray.items

        Item {
            id: item

            required property SystemTrayItem modelData

            width: Theme.barSize - Theme.space3
            height: Theme.barSize - Theme.space4

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusM
                color: mouse.containsMouse ? Theme.surface2 : Theme.transparent
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: item.modelData.icon
                asynchronous: true
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    const data = item.modelData;
                    if (event.button === Qt.RightButton || data.onlyMenu) {
                        if (data.hasMenu) {
                            const p = item.mapToItem(null, root.vertical ? item.width : 0, root.vertical ? 0 : item.height);
                            data.display(root.window, p.x, p.y);
                        }
                    } else {
                        data.activate();
                    }
                }
                onWheel: event => item.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }
}
