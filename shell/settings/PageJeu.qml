import Quickshell
import QtQuick
import qs
import qs.components
import qs.services

Column {
    width: parent ? parent.width : 700

    PageTitle {
        title: "Mode jeu"
        subtitle: "Steam en plein écran dans gamescope, comme sur SteamOS. Super + G pour y passer, « Revenir au bureau » dans Steam pour revenir."
    }

    SettingRow {
        title: "Au démarrage"
        subtitle: "Session ouverte après la connexion."
        OChoice {
            model: [{ id: "derniere", label: "La dernière" }, { id: "bureau", label: "Bureau" }, { id: "jeu", label: "Mode jeu" }]
            current: Reglages.startSession
            onChosen: id => Reglages.startSession = id
        }
    }
    SettingRow {
        title: "Ouverture automatique"
        subtitle: "Pas d'écran de connexion au démarrage, comme une console. Demande le mot de passe administrateur."
        Row {
            spacing: Theme.space2
            OButton {
                text: "Activer"
                onClicked: Quickshell.execDetached(["pkexec", "orbe-autologin", "on", Quickshell.env("USER")])
            }
            OButton {
                text: "Désactiver"
                onClicked: Quickshell.execDetached(["pkexec", "orbe-autologin", "off"])
            }
        }
    }
    SettingRow {
        title: "Passer en mode jeu maintenant"
        subtitle: "Les applications ouvertes sont d'abord fermées proprement."
        OButton {
            text: "Mode jeu"
            accent: true
            onClicked: {
                Panels.settingsOpen = false;
                Session.run("game");
            }
        }
    }
    SettingRow {
        title: "Compteur d'images (MangoHud)"
        subtitle: "Bureau : option de lancement Steam « mangohud %command% », Maj droite + F12 pour l'afficher. Mode jeu : menu rapide de Steam, Performances."
    }
    SettingRow {
        title: "Performances maximales (GameMode)"
        subtitle: "Option de lancement Steam « gamemoderun %command% »."
    }
}
