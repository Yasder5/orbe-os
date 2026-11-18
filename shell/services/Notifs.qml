pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs

// Serveur de notifications d'Orbe : bulles à l'écran et historique (centre de notifications).
Singleton {
    id: root

    // Historique : notifications gardées jusqu'à ce qu'on les efface.
    readonly property var history: server.trackedNotifications.values.slice().reverse()
    readonly property int count: server.trackedNotifications.values.length
    // Bulles affichées en ce moment.
    property list<QtObject> popups: []
    readonly property bool doNotDisturb: Config.doNotDisturb

    function hidePopup(notification) {
        popups = popups.filter(n => n !== notification);
    }

    function dismiss(notification) {
        hidePopup(notification);
        notification.dismiss();
    }

    function clear() {
        popups = [];
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function toggleDoNotDisturb() {
        Config.doNotDisturb = !Config.doNotDisturb;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            // Ne pas déranger : seules les notifications critiques s'affichent.
            if (!root.doNotDisturb || notification.urgency === NotificationUrgency.Critical)
                root.popups = [notification, ...root.popups];
            notification.closed.connect(() => root.hidePopup(notification));
        }
    }

    IpcHandler {
        target: "notifications"

        function clear(): void {
            root.clear();
        }
        function toggleDnd(): void {
            root.toggleDoNotDisturb();
        }
    }
}
