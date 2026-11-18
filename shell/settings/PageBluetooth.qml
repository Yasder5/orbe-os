import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: page

    width: parent ? parent.width : 700

    PageTitle {
        title: "Bluetooth"
        subtitle: "Manettes, casques, claviers. Un appareil doit être en mode appairage pour apparaître."
    }

    SettingRow {
        title: "Bluetooth"
        subtitle: Bt.label
        OSwitch {
            visible: Bt.available
            checked: Bt.enabled
            onToggled: v => Bt.setEnabled(v)
        }
    }

    Repeater {
        model: Bt.enabled ? Bt.devices : []
        ListRow {
            required property var modelData
            width: page.width
            icon: modelData.icon && modelData.icon.indexOf("gaming") >= 0 ? "gamepad" : "bluetooth"
            title: modelData.name || modelData.address
            subtitle: modelData.connected ? (modelData.batteryAvailable ? "Connecté, batterie " + Math.round(modelData.battery * 100) + " %" : "Connecté")
                                          : modelData.paired ? "Appairé" : "Disponible"
            selected: modelData.connected
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.paired)
                    modelData.connect();
                else
                    modelData.pair();
            }
        }
    }

    Component.onCompleted: Bt.scan(true)
    Component.onDestruction: Bt.scan(false)
}
