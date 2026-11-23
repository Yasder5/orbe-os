import QtQuick
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

Column {
    width: parent ? parent.width : 700

    PageTitle {
        title: "Énergie"
        subtitle: "Mise en veille, écran et profil d'énergie. La veille attend la fin d'une musique, d'un téléchargement ou d'une partie."
    }

    SettingRow {
        title: "Profil d'énergie"
        subtitle: "Aussi dans les réglages rapides (Super + A)."
        OChoice {
            model: [{ id: "saver", label: "Économie" }, { id: "balanced", label: "Équilibré" }, { id: "performance", label: "Performances" }]
            current: PowerProfiles.profile === PowerProfile.PowerSaver ? "saver" : PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced"
            onChosen: id => PowerProfiles.profile = id === "saver" ? PowerProfile.PowerSaver : id === "performance" ? PowerProfile.Performance : PowerProfile.Balanced
        }
    }
    SettingRow {
        title: "Mise en veille automatique"
        OChoice {
            model: [{ id: 0, label: "Jamais" }, { id: 30, label: "30 min" }, { id: 60, label: "1 h" }, { id: 120, label: "2 h" }].map(o => ({ id: String(o.id), label: o.label }))
            current: String(Reglages.veille)
            onChosen: id => {
                Reglages.veille = parseInt(id);
                Reglages.applyEnergie();
            }
        }
    }
    SettingRow {
        title: "Éteindre l'écran"
        OChoice {
            model: [{ id: "0", label: "Jamais" }, { id: "5", label: "5 min" }, { id: "11", label: "11 min" }, { id: "30", label: "30 min" }]
            current: String(Reglages.ecranEteint)
            onChosen: id => {
                Reglages.ecranEteint = parseInt(id);
                Reglages.applyEnergie();
            }
        }
    }
    SettingRow {
        title: "Verrouiller la session"
        subtitle: "Après une absence. Super + L verrouille tout de suite."
        OChoice {
            model: [{ id: "0", label: "Jamais" }, { id: "5", label: "5 min" }, { id: "10", label: "10 min" }, { id: "30", label: "30 min" }]
            current: String(Reglages.verrouillage)
            onChosen: id => {
                Reglages.verrouillage = parseInt(id);
                Reglages.applyEnergie();
            }
        }
    }
    SettingRow {
        visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
        title: "Batterie"
        subtitle: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + " %" + (UPower.onBattery ? ", sur batterie" : ", sur secteur") : ""
    }
}
