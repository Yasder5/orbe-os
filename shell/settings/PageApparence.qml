import QtQuick
import qs
import qs.components
import qs.services

Column {
    width: parent ? parent.width : 700

    PageTitle {
        title: "Apparence"
        subtitle: "Barre, fond d'écran, animations et sons. Tout s'applique tout de suite."
    }

    SettingRow {
        title: "Position de la barre"
        OChoice {
            model: [{ id: "left", label: "À gauche" }, { id: "top", label: "En haut" }]
            current: Config.barPosition
            onChosen: id => Config.barPosition = id
        }
    }
    SettingRow {
        title: "Fond d'écran"
        subtitle: Config.wallpaper === "orbe-vivant" ? "Orbe vivant (animé)" : Config.wallpaper.split("/").pop()
        OButton {
            text: "Choisir"
            onClicked: {
                Panels.settingsOpen = false;
                Panels.toggleWallpaper();
            }
        }
    }
    SettingRow {
        title: "Réduire les animations"
        subtitle: "Coupe les mouvements et l'orbe animé (accessibilité, économie d'énergie)."
        OSwitch {
            checked: Config.reduceMotion
            onToggled: v => Config.reduceMotion = v
        }
    }
    SettingRow {
        title: "Horloge sur 24 heures"
        OSwitch {
            checked: Config.clock24h
            onToggled: v => Config.clock24h = v
        }
    }
    SettingRow {
        title: "Sons système"
        subtitle: "Notifications et réglage du volume."
        OSwitch {
            checked: Config.sounds
            onToggled: v => Config.sounds = v
        }
    }
    SettingRow {
        title: "Mode nuit"
        subtitle: "Couleurs plus chaudes : " + Config.nightTemperature + " K"
        Row {
            spacing: Theme.space3
            OSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: 180
                value: (6500 - Config.nightTemperature) / 3500
                onMoved: v => Config.nightTemperature = Math.round((6500 - v * 3500) / 100) * 100
            }
            OSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: Config.nightLight
                onToggled: Night.toggle()
            }
        }
    }
    SettingRow {
        title: "Ne pas déranger"
        subtitle: "Seules les notifications urgentes s'affichent."
        OSwitch {
            checked: Notifs.doNotDisturb
            onToggled: Notifs.toggleDoNotDisturb()
        }
    }
}
