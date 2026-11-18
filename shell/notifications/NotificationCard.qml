// Carte de notification : icône, application, titre, texte, image et actions.
// En bulle : disparaît seule (pause au survol), se ferme en la glissant sur le côté.

import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.components
import qs.services

Item {
    id: card

    required property var notification
    property bool popup: true
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property string appIconSource: notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : ""
    readonly property int timeout: notification.expireTimeout > 0 ? notification.expireTimeout : 6000
    property real swipe: 0
    property bool entered: false

    implicitWidth: 380
    implicitHeight: content.implicitHeight + Theme.space4 * 2
    opacity: entered ? 1 - Math.min(1, Math.abs(swipe) / 260) : 0
    transform: Translate {
        x: card.entered ? card.swipe : 40
    }

    Component.onCompleted: entered = true

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curve
        }
    }

    function close() {
        if (popup)
            Notifs.hidePopup(notification);
        else
            Notifs.dismiss(notification);
    }

    // Disparition automatique des bulles (sauf notifications critiques), en pause au survol.
    Timer {
        running: card.popup && !card.critical && !hover.hovered && !drag.active
        interval: card.timeout
        onTriggered: card.close()
    }

    RectangularShadow {
        anchors.fill: background
        visible: card.popup
        offset.y: 18
        blur: 40
        radius: Theme.radiusL
        color: Theme.shadow
    }

    Rectangle {
        id: background

        anchors.fill: parent
        radius: Theme.radiusL
        color: card.popup ? Theme.panel : Theme.surface2
        border.width: 1
        border.color: card.critical ? Theme.danger : Theme.line
    }

    HoverHandler {
        id: hover
    }

    // Glisser sur le côté pour fermer.
    DragHandler {
        id: drag

        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        onTranslationChanged: card.swipe = translation.x
        onActiveChanged: {
            if (active)
                return;
            if (Math.abs(card.swipe) > 120)
                Notifs.dismiss(card.notification);
            else
                card.swipe = 0;
        }
    }

    Behavior on swipe {
        enabled: !drag.active
        NumberAnimation {
            duration: Theme.durMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curve
        }
    }

    // Clic sur la carte : action par défaut de l'application, s'il y en a une.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const action = card.notification.actions.find(a => a.identifier === "default");
            if (action)
                action.invoke();
            card.close();
        }
    }

    Row {
        id: content

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.space4
        }
        spacing: Theme.space3

        Item {
            width: 32
            height: 32

            IconImage {
                anchors.fill: parent
                visible: card.appIconSource !== ""
                source: card.appIconSource
                asynchronous: true
            }
            Icon {
                anchors.centerIn: parent
                visible: card.appIconSource === ""
                name: "bell"
                color: card.critical ? Theme.danger : Theme.accent
            }
        }

        Column {
            width: parent.width - 32 - Theme.space3 - (image.visible ? image.width + Theme.space3 : 0)
            spacing: Theme.space1

            Row {
                width: parent.width
                spacing: Theme.space2

                OText {
                    width: parent.width - closeButton.width - Theme.space2
                    text: card.notification.appName || "Notification"
                    mono: true
                    font.pixelSize: Theme.textXs
                    color: Theme.muted
                }

                Icon {
                    id: closeButton

                    width: 16
                    height: 16
                    name: "close"
                    color: closeMouse.containsMouse ? Theme.text : Theme.muted
                    opacity: hover.hovered ? 1 : 0

                    MouseArea {
                        id: closeMouse

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismiss(card.notification)
                    }
                }
            }

            OText {
                width: parent.width
                text: card.notification.summary
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            OText {
                width: parent.width
                visible: text !== ""
                text: card.notification.body
                textFormat: Text.StyledText
                font.pixelSize: Theme.textS
                color: Theme.muted
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 4 : 8
            }

            Flow {
                width: parent.width
                spacing: Theme.space2
                visible: actionsRepeater.count > 0
                topPadding: Theme.space1

                Repeater {
                    id: actionsRepeater

                    model: card.notification.actions.filter(a => a.identifier !== "default")

                    Rectangle {
                        required property var modelData

                        width: actionLabel.implicitWidth + Theme.space4 * 2
                        height: 30
                        radius: Theme.radiusS
                        color: actionMouse.containsMouse ? Theme.line2 : Theme.line

                        OText {
                            id: actionLabel

                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.pixelSize: Theme.textS
                        }

                        MouseArea {
                            id: actionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                parent.modelData.invoke();
                                card.close();
                            }
                        }
                    }
                }
            }
        }

        ClippingRectangle {
            id: image

            width: 56
            height: 56
            radius: Theme.radiusS
            visible: card.notification.image !== ""
            color: Theme.surface2

            Image {
                anchors.fill: parent
                source: card.notification.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }
}
