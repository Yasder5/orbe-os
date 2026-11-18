# Orbe Shell : architecture

Orbe Shell est une configuration Quickshell (QML, Qt 6) nommée `orbe`, installée dans `/etc/xdg/quickshell/orbe` par le paquet `orbe-shell` et lancée par Hyprland avec `qs -c orbe`. Réécriture inspirée de l'ergonomie de Caelestia Shell, sans reprise de son code.

## Organisation de `shell/`

| Fichier ou dossier | Rôle |
|---|---|
| `shell.qml` | point d'entrée : instancie chaque module |
| `Theme.qml` | **seul endroit** où sont écrits couleurs, polices, rayons, durées et espacements |
| `Config.qml` | réglages de l'utilisateur, `~/.config/orbe/shell.json`, rechargés à chaud |
| `Panels.qml` | ce qui est ouvert à l'écran (lanceur, menu de session, centre) et ses points d'entrée IPC |
| `Icons.qml` | icônes Orbe monolignes (tracés SVG sur une grille de 24 px) |
| `services/` | données du système : son (PipeWire), luminosité, verrouillage majuscules, notifications, applications, actions de session |
| `components/` | éléments réutilisables : icône, texte, anneau de focus, bouton de panneau, orbe animé, logo |
| `bar/` | barre, verticale à gauche ou horizontale en haut |
| `launcher/` | lanceur d'applications et ses préfixes, liste d'émojis générée par `tools/gen-emojis.py` |
| `notifications/` | bulles et centre de notifications |
| `osd/` | jauge de volume, luminosité et verrouillage majuscules |
| `session/` | menu de session plein écran |
| `lock/` | écran de verrouillage et sa configuration PAM (`lock/pam/orbe-lock`) |
| `wallpaper/` | fond d'écran (image ou orbe animé) et sélecteur |
| `quicksettings/` | réglages rapides |
| `dashboard/` | tableau de bord (accueil, système, média) et réglage de cava |
| `shaders/` | orbe de particules en shader (`orb.frag`, compilé en `.qsb` par `tools/build-shaders.sh`) |
| `scripts/` | mesures système du tableau de bord |

## Réglages (`~/.config/orbe/shell.json`)

Créé au premier lancement. Toute modification est appliquée sans redémarrer le shell. `wallpaper` accepte un chemin d'image ou `orbe-vivant` (orbe animé).

```json
{
  "barPosition": "left",
  "reduceMotion": false,
  "doNotDisturb": false,
  "clock24h": true,
  "wallpaper": "/usr/share/backgrounds/orbe/orbe.png",
  "weatherCity": "Paris",
  "nightLight": false,
  "nightTemperature": 4500
}
```

## Commandes IPC

Utilisées par les raccourcis de `packages/orbe-desktop/binds.lua`, et utilisables dans des scripts :

| Commande | Effet |
|---|---|
| `qs -c orbe ipc call launcher toggle` | ouvre ou ferme le lanceur |
| `qs -c orbe ipc call launcher open "=2+2"` | ouvre le lanceur avec un texte (et donc un préfixe) |
| `qs -c orbe ipc call session toggle` | menu de session |
| `qs -c orbe ipc call center toggle` | centre de notifications |
| `qs -c orbe ipc call notifications toggleDnd` | Ne pas déranger |
| `qs -c orbe ipc call brightness up` / `down` | luminosité, avec OSD |
| `qs -c orbe ipc call keyboard capslock` | relit le voyant Verr. Maj et affiche l'OSD |
| `qs -c orbe ipc call osd flash volume` | affiche l'OSD (`volume`, `brightness`, `capslock`) |
| `qs -c orbe ipc call dashboard toggle` / `tab systeme` | tableau de bord, ou un onglet (`accueil`, `systeme`, `media`) |
| `qs -c orbe ipc call quick toggle` | réglages rapides |
| `qs -c orbe ipc call wallpaper picker` | sélecteur de fond d'écran |
| `qs -c orbe ipc call lock lock` | verrouille (appelé par hypridle et Super + L) |

`qs -c orbe ipc show` liste tout ce qui est disponible.

## Calques Wayland

Chaque fenêtre du shell a un espace de noms `orbe-*` (`orbe-bar`, `orbe-launcher`, `orbe-session`, ...). La règle `orbe-shell-blur` de Hyprland floute ce qui se trouve derrière les zones opaques à plus de 20 % : le flou reste réservé au shell.

## Essayer sans construire l'ISO

`tools/shell-preview.sh` lance le shell depuis `shell/` dans un compositeur sans écran (sway) et prend une capture dans `out/captures/` : quelques secondes au lieu d'une ISO et d'une machine virtuelle. Les modules propres à Hyprland y restent vides. Exemples :

```bash
tools/shell-preview.sh --ipc "launcher toggle"
```

```bash
tools/shell-preview.sh --name calcul --ipc "launcher open =(12+3)*4^2"
```

## Pièges connus

- Une propriété QML qui commence par `on` suivi d'une majuscule est prise pour un gestionnaire de signal (`onAccent` est invalide).
- Un singleton ne doit pas porter le nom d'un type Qt Quick (`State` est déjà un type).
- Une fonction IPC ne peut pas s'appeler `show` : la commande `qs ipc` la prend pour sa sous-commande.
- Le moteur JavaScript de QML ne gère pas l'étalement d'objet (`{ ...a }`) : utiliser `Object.assign`. L'étalement de tableau (`[...a]`) fonctionne.
- Les singletons sont créés à leur première utilisation : `shell.qml` les touche au démarrage pour que leurs points d'entrée IPC existent.
