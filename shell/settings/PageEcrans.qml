import QtQuick
import qs
import qs.components
import qs.services

Column {
    width: parent ? parent.width : 700
    spacing: Theme.space5

    PageTitle {
        title: "Écrans"
        subtitle: "Définition, fréquence, échelle et position de chaque écran. Enregistré dans ~/.config/orbe/hyprland.lua."
    }

    OText {
        visible: Reglages.outputs.length === 0
        text: "Aucun écran trouvé (Hyprland ne répond pas)."
        color: Theme.muted
    }

    Repeater {
        model: Reglages.outputs

        Column {
            id: screenBlock

            required property var modelData

            width: parent.width

            OText {
                text: screenBlock.modelData.model + "  ·  " + screenBlock.modelData.name
                font.weight: Font.DemiBold
                bottomPadding: Theme.space2
            }
            SettingRow {
                id: modeRow

                property bool expanded: false

                title: "Définition et fréquence"
                subtitle: "Actuellement " + screenBlock.modelData.mode.replace("@", " à ") + " Hz"
                OButton {
                    text: modeRow.expanded ? "Fermer" : "Choisir"
                    onClicked: modeRow.expanded = !modeRow.expanded
                }
            }
            // Tous les modes de l'écran, fréquence la plus haute d'abord pour chaque définition.
            Column {
                visible: modeRow.expanded
                width: parent.width

                Repeater {
                    model: ["highrr", "preferred"].concat([...new Set(screenBlock.modelData.modes)].sort((a, b) => {
                        const [ra, fa] = a.split("@"), [rb, fb] = b.split("@");
                        const pa = ra.split("x").reduce((x, y) => x * y), pb = rb.split("x").reduce((x, y) => x * y);
                        return pb - pa || parseFloat(fb) - parseFloat(fa);
                    }))

                    ListRow {
                        required property string modelData

                        width: parent.width
                        icon: "apps"
                        title: modelData === "highrr" ? "Automatique : fréquence la plus haute"
                             : modelData === "preferred" ? "Automatique : mode conseillé par l'écran"
                             : modelData.replace(/\.\d+$/, "").replace("@", " à ") + " Hz"
                        selected: ((Reglages.monitors[screenBlock.modelData.name] || {}).mode || "highrr") === modelData
                        onClicked: Reglages.setMonitor(screenBlock.modelData.name, "mode", modelData)
                    }
                }
            }
            SettingRow {
                title: "Échelle"
                subtitle: "Taille du texte et des fenêtres."
                OChoice {
                    model: [{ id: "auto", label: "Auto" }, { id: "1", label: "100 %" }, { id: "1.25", label: "125 %" }, { id: "1.5", label: "150 %" }, { id: "2", label: "200 %" }]
                    current: String((Reglages.monitors[screenBlock.modelData.name] || {}).scale || "auto")
                    onChosen: id => Reglages.setMonitor(screenBlock.modelData.name, "scale", id)
                }
            }
            SettingRow {
                visible: Reglages.outputs.length > 1
                title: "Position"
                subtitle: "Par rapport aux autres écrans."
                OChoice {
                    model: [{ id: "auto", label: "Auto" }, { id: "auto-left", label: "À gauche" }, { id: "auto-right", label: "À droite" }, { id: "auto-up", label: "Au-dessus" }]
                    current: (Reglages.monitors[screenBlock.modelData.name] || {}).position || "auto"
                    onChosen: id => Reglages.setMonitor(screenBlock.modelData.name, "position", id)
                }
            }
        }
    }
}
