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
    // Pendant un jeu ou une vidéo en plein écran : pas de bulle ni de son (elles passeraient
    // par-dessus le jeu), un résumé à la sortie du plein écran. Tout reste dans le centre.
    readonly property bool quiet: doNotDisturb || Panels.anyFullscreen
    property int missed: 0

    Connections {
        target: Panels
        function onAnyFullscreenChanged() {
            if (!Panels.anyFullscreen && root.missed > 0 && !root.doNotDisturb) {
                const n = root.missed;
                root.missed = 0;
                Quickshell.execDetached(["notify-send", "-a", "Orbe", "-i", "preferences-system-notifications",
                    n === 1 ? "Une notification pendant le plein écran" : n + " notifications pendant le plein écran",
                    "Elles sont dans le centre de notifications (Super + N)."]);
            }
        }
    }

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
            // Ne pas déranger ou plein écran : seules les notifications critiques s'affichent.
            if (!root.quiet || notification.urgency === NotificationUrgency.Critical) {
                root.popups = [notification, ...root.popups];
                Sounds.play(notification.urgency === NotificationUrgency.Critical ? "dialog-warning" : "message-new-instant");
            } else if (Panels.anyFullscreen && !root.doNotDisturb) {
                root.missed++;
            }
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
