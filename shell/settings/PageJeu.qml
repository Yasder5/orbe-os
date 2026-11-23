import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: page

    property bool nvidia: false
    property bool lib32: true

    width: parent ? parent.width : 700

    // Carte NVIDIA et bibliothèques 32 bits (Steam, Proton).
    Process {
        running: true
        command: ["sh", "-c", "grep -lqx 0x10de /sys/bus/pci/devices/*/vendor 2>/dev/null && grep -qE '^0x030[02]' $(dirname $(grep -lx 0x10de /sys/bus/pci/devices/*/vendor))/class 2>/dev/null && echo nvidia; pacman -Q lib32-nvidia-utils >/dev/null 2>&1 && echo lib32"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.nvidia = text.indexOf("nvidia") >= 0;
                page.lib32 = text.indexOf("lib32") >= 0;
            }
        }
    }

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
        visible: Reglages.outputs.length > 1
        title: "Écran du mode jeu"
        subtitle: "gamescope n'utilise qu'un écran."
        OChoice {
            model: [{ id: "", label: "Le premier" }].concat(Reglages.outputs.map(o => ({ id: o.name, label: o.name })))
            current: Reglages.jeuEcran
            onChosen: id => {
                Reglages.jeuEcran = id;
                Reglages.applyJeu();
            }
        }
    }
    SettingRow {
        title: "Performances maximales"
        subtitle: "Profil d'énergie « performances » pendant le mode jeu, rendu à la sortie."
        OSwitch {
            checked: Reglages.jeuPerf
            onToggled: v => {
                Reglages.jeuPerf = v;
                Reglages.applyJeu();
            }
        }
    }
    SettingRow {
        title: "Moteur"
        subtitle: "Secours : Steam en plein écran sans gamescope, si gamescope ne fonctionne pas avec ta carte graphique. Choisi tout seul après deux échecs de suite."
        OChoice {
            model: [{ id: "gamescope", label: "gamescope" }, { id: "secours", label: "Secours" }]
            current: Reglages.jeuMoteur
            onChosen: id => {
                Reglages.jeuMoteur = id;
                Reglages.applyJeu();
            }
        }
    }
    SettingRow {
        title: "Steam en arrière-plan sur le bureau"
        subtitle: "La manette sert de souris et de clavier, le bouton Guide ouvre Big Picture. Au prochain démarrage de session."
        OSwitch {
            checked: Reglages.steamFond
            onToggled: v => {
                Reglages.steamFond = v;
                Reglages.applyJeu();
            }
        }
    }
    SettingRow {
        visible: page.nvidia
        title: "Pilote NVIDIA 32 bits"
        subtitle: page.lib32 ? "Installé : Steam et Proton l'utilisent." : "Absent : Steam et les jeux Proton en ont besoin. Demande Internet et ton mot de passe."
        OButton {
            visible: !page.lib32
            text: "Installer"
            accent: true
            onClicked: Quickshell.execDetached(["foot", "-T", "Pilote NVIDIA", "-H", "sudo", "orbe-nvidia"])
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
        title: "Enregistrer ses parties"
        subtitle: "Super + Maj + R : enregistrer l'écran. Relecture (lanceur, /) puis Super + Maj + G : garder les 30 dernières secondes. Vidéos dans ~/Vidéos/Orbe."
    }

    Component.onCompleted: Reglages.refreshOutputs()
}
