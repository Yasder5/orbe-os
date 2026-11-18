import Quickshell
import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: page

    width: parent ? parent.width : 700

    PageTitle {
        title: "Réseau"
        subtitle: Network.label
    }

    SettingRow {
        title: "Wi-Fi"
        subtitle: Network.wifi ? (Network.activeWifi ? "Connecté à " + Network.activeWifi.name : "Non connecté") : "Pas de carte Wi-Fi"
        OSwitch {
            visible: Network.wifi !== null
            checked: Network.wifiEnabled
            onToggled: v => Network.setWifi(v)
        }
    }

    OText {
        visible: Network.wifiEnabled && Network.networks.length > 0
        text: "Réseaux à portée"
        font.weight: Font.DemiBold
        topPadding: Theme.space5
        bottomPadding: Theme.space2
    }
    Repeater {
        model: Network.wifiEnabled ? Network.networks : []
        ListRow {
            required property var modelData
            width: page.width
            icon: "wifi"
            title: modelData.name
            subtitle: modelData.connected ? "Connecté" : modelData.known ? "Enregistré" : Math.round(modelData.signalStrength * 100) + " %"
            selected: modelData.connected
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.known)
                    modelData.connect();
                else {
                    // Mot de passe saisi dans les réglages rapides.
                    Panels.settingsOpen = false;
                    Panels.toggleQuick();
                }
            }
        }
    }

    SettingRow {
        title: "Réglages avancés"
        subtitle: "Adresse IP fixe, VPN, partage de connexion : nmtui dans un terminal."
        OButton {
            text: "Ouvrir"
            onClicked: Quickshell.execDetached(["foot", "-T", "Réseau", "nmtui"])
        }
    }

    Component.onCompleted: Network.scan(true)
    Component.onDestruction: Network.scan(false)
}
