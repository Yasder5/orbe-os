# Orbe Shell : architecture

Orbe Shell est une configuration Quickshell (QML, Qt 6) nommée `orbe`, installée dans `/etc/xdg/quickshell/orbe` par le paquet `orbe-shell` et lancée par Hyprland avec `qs -c orbe`. Réécriture inspirée de l'ergonomie de Caelestia Shell, sans reprise de son code.

## Organisation de `shell/`

| Fichier ou dossier | Rôle |
|---|---|
| `shell.qml` | point d'entrée : instancie chaque module |
| `Theme.qml` | **seul endroit** où sont écrits couleurs, polices, rayons, durées et espacements ; liste des couleurs d'accent (`accents`) |
| `Config.qml` | réglages de l'utilisateur, `~/.config/orbe/shell.json`, rechargés à chaud |
| `Panels.qml` | ce qui est ouvert à l'écran (lanceur, menu de session, centre) et ses points d'entrée IPC |
| `Icons.qml` | icônes Orbe monolignes (tracés SVG sur une grille de 24 px) |
| `services/` | données du système : son (PipeWire), luminosité, verrouillage majuscules, notifications, applications, actions de session (dont le mode jeu), sons système |
| `components/` | éléments réutilisables : icône, texte, anneau de focus, bouton de panneau, orbe animé, logo, image de fond recolorée (`Fond.qml`), choix de couleur (`AccentChoice.qml`) |
| `bar/` | barre, verticale à gauche ou horizontale en haut |
| `launcher/` | lanceur d'applications et ses préfixes, liste d'émojis générée par `tools/gen-emojis.py` |
| `notifications/` | bulles et centre de notifications |
| `osd/` | jauge de volume, luminosité et verrouillage majuscules |
| `session/` | menu de session plein écran |
| `lock/` | écran de verrouillage et sa configuration PAM (`lock/pam/orbe-lock`) |
| `wallpaper/` | fond d'écran (image ou orbe animé) et sélecteur |
| `quicksettings/` | réglages rapides |
| `dashboard/` | tableau de bord (accueil, système, média) et réglage de cava |
| `settings/` | application « Réglages Orbe » (une page par fichier `Page*.qml`) |
| `welcome/` | assistant de bienvenue du premier lancement (et proposition d'installer, en live) |
| `help/` | aide des raccourcis clavier |
| `greeter/`, `greeter.qml` | écran de connexion de greetd (`orbe-greeter` lance `qs -p .../greeter.qml` dans cage) |
| `shaders/` | orbe de particules (`orb.frag`) et recoloration des fonds d'Orbe (`recolor.frag`), compilés en `.qsb` par `tools/build-shaders.sh` |
| `scripts/` | mesures système du tableau de bord |

## Réglages (`~/.config/orbe/shell.json`)

Créé au premier lancement. Toute modification est appliquée sans redémarrer le shell. `wallpaper` accepte un chemin d'image ou `orbe-vivant` (orbe animé). `accent` vaut `citron` (par défaut), `menthe`, `ciel`, `lavande`, `rose` ou `ambre`. `sounds` coupe ou rétablit les sons système (notification, volume).

```json
{
  "barPosition": "left",
  "reduceMotion": false,
  "doNotDisturb": false,
  "clock24h": true,
  "wallpaper": "/usr/share/backgrounds/orbe/orbe.png",
  "weatherCity": "Paris",
  "nightLight": false,
  "nightTemperature": 4500,
  "sounds": true,
  "accent": "citron"
}
```

## Couleur d'accent

Choisie dans Réglages, Apparence, ou à l'accueil. Toutes les variantes gardent au moins 9:1 de contraste avec le fond et avec le texte noir posé dessus.

- **Shell** : `Theme.accent` suit `Config.accent` ; les fonds fournis par Orbe (`/usr/share/backgrounds/orbe`) sont recolorés à l'affichage par `shaders/recolor.frag` (le citron devient la couleur choisie, le noir et les étoiles blanches ne bougent pas). Les images de l'utilisateur ne sont pas touchées.
- **Hors du shell** : `services/Accent.qml` lance `orbe-accent NOM` au démarrage et à chaque changement. Le script écrit `~/.config/orbe/couleurs.lua` (bordure de la fenêtre active, chargé par `orbe.lua`, puis `hyprctl reload`) et des copies recolorées des thèmes dans `~/.config/orbe/couleurs/` : GTK 3 et 4, Qt (qt6ct), foot, fish, Starship, btop ; les réglages de l'utilisateur y renvoient. Avec le citron, ils renvoient aux fichiers d'Orbe et les copies sont effacées. Les couleurs ANSI du terminal (le vert reste vert) et les lignes changées par l'utilisateur ne sont pas touchées.
- **Restent en citron** : écran de connexion, démarrage (Plymouth, GRUB), installateur, thème Steam, Heroic et MangoHud. Les applications GTK et Qt déjà ouvertes prennent la couleur à leur prochain lancement.

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
| `qs -c orbe ipc call settings open apparence` | Réglages Orbe, sur une page (`apparence`, `ecrans`, `clavier`, `son`, `reseau`, `bluetooth`, `jeu`, `comptes`, `maj`, `apropos`) |
| `qs -c orbe ipc call help toggle` | aide des raccourcis |
| `qs -c orbe ipc call welcome open` / `step 3` | assistant de bienvenue, ou une de ses étapes |

`qs -c orbe ipc show` liste tout ce qui est disponible.

## Réglages de Hyprland (`~/.config/orbe/reglages.json`)

Écrans, clavier, souris et pavé tactile réglés dans « Réglages Orbe ». Le service `Reglages` les traduit en Lua dans `~/.config/orbe/hyprland.lua`, chargé à la fin de la configuration Hyprland d'Orbe, puis lance `hyprctl reload`. `startSession` (`derniere`, `bureau`, `jeu`) est recopié dans `~/.config/orbe/demarrage`, lu par `orbe-session`.

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
