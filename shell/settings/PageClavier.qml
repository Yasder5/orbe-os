import QtQuick
import qs
import qs.components
import qs.services

Column {
    width: parent ? parent.width : 700

    PageTitle {
        title: "Clavier et souris"
        subtitle: "Disposition du clavier, vitesse du pointeur et pavé tactile."
    }

    SettingRow {
        title: "Disposition du clavier"
        OChoice {
            model: [
                { id: "fr", label: "Français" }, { id: "be", label: "Belge" }, { id: "ch", label: "Suisse" },
                { id: "ca", label: "Canadien" }, { id: "us", label: "Anglais (US)" }
            ]
            current: Reglages.kbLayout
            onChosen: id => {
                Reglages.kbLayout = id;
                Reglages.kbVariant = id === "ch" ? "fr" : id === "ca" ? "fr" : "";
                Reglages.apply();
            }
        }
    }
    SettingRow {
        title: "Vitesse du pointeur"
        subtitle: Reglages.sensitivity === 0 ? "Normale" : (Reglages.sensitivity > 0 ? "+" : "") + Math.round(Reglages.sensitivity * 100) + " %"
        OSlider {
            width: 220
            value: (Reglages.sensitivity + 1) / 2
            onMoved: v => {
                Reglages.sensitivity = Math.round((v * 2 - 1) * 20) / 20;
                Reglages.apply();
            }
        }
    }
    SettingRow {
        title: "Accélération du pointeur"
        subtitle: "Coupée par défaut : la visée reste constante en jeu."
        OSwitch {
            checked: !Reglages.accelFlat
            onToggled: v => {
                Reglages.accelFlat = !v;
                Reglages.apply();
            }
        }
    }
    SettingRow {
        title: "Défilement naturel"
        subtitle: "Pavé tactile : le contenu suit les doigts."
        OSwitch {
            checked: Reglages.naturalScroll
            onToggled: v => {
                Reglages.naturalScroll = v;
                Reglages.apply();
            }
        }
    }
    SettingRow {
        title: "Toucher pour cliquer"
        OSwitch {
            checked: Reglages.tapToClick
            onToggled: v => {
                Reglages.tapToClick = v;
                Reglages.apply();
            }
        }
    }
    SettingRow {
        title: "Raccourcis clavier"
        subtitle: "La liste complète, aussi avec Super + Maj + :"
        OButton {
            text: "Afficher"
            onClicked: {
                Panels.settingsOpen = false;
                Panels.helpOpen = true;
            }
        }
    }
}
