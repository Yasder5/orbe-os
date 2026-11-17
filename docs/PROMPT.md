# Mission : Orbe OS, distribution Linux basée sur Arch

Tu vas construire **Orbe OS** : une distribution Linux basée sur Arch Linux, livrée sous forme d'ISO bootable et installable. Elle a un bureau Wayland complet inspiré de **Caelestia Shell** (https://github.com/caelestia-dots/shell), habillé entièrement aux couleurs de l'univers **Orbe**. Elle doit être utilisable au quotidien dès le premier démarrage, sans aucune configuration à faire par l'utilisateur.

Tu travailles en autonomie, étape par étape. Tu testes chaque étape avant de passer à la suivante. Tu tiens un journal de ce qui est fait, de ce qui reste à faire et des décisions prises.

## 0. Règles de travail (obligatoires)

- Réponds en français, de façon concise. Commandes shell sur une ligne.
- Dépôt git dans `~/orbe-os`. Commits au nom de `yasder5`, sans aucune mention de Claude ni ligne `Co-Authored-By`. Pas de `git push` sans mon accord.
- Aucun secret (jeton, mot de passe, clé) dans le dépôt ni dans le chat. Les secrets vont dans un `.env` en 600, ignoré par git.
- `sudo` me demande un mot de passe : quand tu en as besoin, donne-moi la commande exacte à lancer avec `! sudo …`.
- Arrête un processus par son PID, jamais avec `pkill -f`.
- Dans les textes visibles (menus, installateur, site, README) : jamais de tiret cadratin « — » (utilise « : », « , », des parenthèses ou « · »). Jamais de pastille qui clignote, de point qui pulse ni de curseur clignotant décoratif. Jamais de numérotation décorative (01, 02, 03).
- Interface et textes en français par défaut, avec l'anglais disponible.
- Avant toute décision lourde (changer de compositeur, de toolkit, de chargeur d'amorçage, abandonner un composant), demande-moi.
- Licences : Caelestia Shell est sous GPL-3.0. Si tu reprends ou forkes du code QML, le code dérivé reste en GPL-3.0, avec crédit et lien vers l'original dans le README et dans `LICENSES/`. Je préfère une réécriture inspirée plutôt qu'un fork qu'on se contente de recolorer. Vérifie la licence de chaque police, icône, curseur et son embarqués.

## 1. L'identité Orbe (à respecter partout)

Orbe est mon univers visuel : portfolio, thème WordPress, Orbe Launcher (un launcher de jeux plein écran pour manette, https://github.com/Yasder5/orbe-launcher), skins Steam et Discord. Le style : noir profond, un seul accent citron vert, typographie grotesque nette, angles presque droits, et un **orbe de particules** lumineux comme signature visuelle.

### Palette (jetons de référence)

| Jeton | Valeur | Usage |
|---|---|---|
| bg | `#0a0a0a` | fond principal |
| bg-2 | `#0d0d0c` | fond secondaire |
| surface | `#121212` | panneaux, barre, cartes |
| surface-2 | `#1a1a19` | survol, éléments imbriqués |
| line | `#262624` | bordures, séparateurs |
| line-2 | `#3a3a37` | bordures appuyées |
| text | `#f5f5f0` | texte principal (blanc cassé chaud) |
| muted | `#8f8f8a` | texte secondaire |
| accent | `#d3fd50` | accent unique (citron vert) |
| accent-hover | `#e1ff80` | survol de l'accent |
| accent-active | `#bde83a` | accent pressé |
| on-accent | `#0a0a0a` | texte posé sur l'accent |
| danger | `#ff6b5a` | erreurs, batterie faible, éteindre |
| glow | `rgba(211, 253, 80, .16)` | halo de l'accent |

- Couleurs ANSI du terminal à dériver de cette palette : fond `#0a0a0a`, texte `#f5f5f0`, vert = accent, rouge = danger. Garde des couleurs lisibles et distinctes pour les 16 teintes, contraste AA minimum.
- Polices : **Archivo** (variable 100 à 900) pour l'interface, **JetBrains Mono** pour le terminal et le code. Les deux sont sous OFL et disponibles dans les dépôts Arch ou sur Google Fonts.
- Rayons : 4 px (petit), 6 px (moyen), 8 px (grand). Pas d'interface toute ronde à la Material.
- Ombres : `0 18px 40px rgba(0,0,0,.55)`. Anneau de focus : `0 0 0 2px #d3fd50` plus un halo `0 0 32px rgba(211,253,80,.28)`.
- Animations : 150 ms, 300 ms, 600 ms, courbe `cubic-bezier(.2,.8,.2,1)`. Mouvements doux, jamais de rebond cartoon. Respecte un réglage « réduire les animations ».
- Signature : un orbe de particules (sphère de points lumineux citron qui tourne lentement). Il sert de logo, de fond d'écran animé optionnel, d'écran de démarrage, d'écran de verrouillage et d'icône du lanceur.
- Un thème clair « Orbe Jour » est un bonus pour la fin du projet, pas une priorité.

Pour coller exactement au rendu, inspire-toi du thème `themes/orbe` d'Orbe Launcher et de `skins/discord/src/orbe.css` dans le dépôt GitHub.

## 2. Base technique

- **Base** : Arch Linux (dépôts officiels), noyau `linux` ; propose aussi `linux-lts` dans l'installateur.
- **ISO** : `archiso`, profil personnalisé dérivé de `releng`. ISO live bootable en UEFI et en BIOS, avec une session live qui lance directement le bureau Orbe.
- **Construction** : mon PC est sous Manjaro et `mkarchiso` veut un vrai Arch. Construis donc dans un conteneur Docker `archlinux:latest` privilégié, avec un script `build.sh` reproductible (une commande pour produire l'ISO). Mets un cache pacman en volume.
- **Dépôt de paquets Orbe** : un dépôt pacman local `[orbe]` (`repo-add`), avec des PKGBUILD pour tout ce qui est maison : `orbe-shell`, `orbe-themes`, `orbe-wallpapers`, `orbe-settings`, `orbe-branding`, `orbe-installer-config`. Les paquets AUR nécessaires sont reconstruits dans ce dépôt pour que l'ISO n'ait aucune dépendance à l'AUR au moment de l'installation.
- **Compositeur** : Hyprland, comme Caelestia.
- **Shell de bureau** : Quickshell (QML, Qt 6). Vérifie s'il est dans les dépôts officiels ou seulement dans l'AUR, puis empaquette-le.
- **Gestionnaire de connexion** : greetd, avec un greeter Quickshell aux couleurs Orbe. Sinon, SDDM avec un thème QML Orbe. Choisis et explique-moi pourquoi.
- **Son** : PipeWire et WirePlumber. **Réseau** : NetworkManager. **Bluetooth** : BlueZ. **Énergie** : power-profiles-daemon. **Portails** : xdg-desktop-portal-hyprland et xdg-desktop-portal-gtk.
- **Pilotes** : mesa et vulkan pour AMD et Intel. Pour NVIDIA, une option dans l'installateur (`nvidia-open-dkms` et les variables Hyprland nécessaires). Mon PC a une RTX 3050 et un Ryzen 7 5800X : ce cas doit marcher.
- **Applications par défaut** (sobres et légères) :
  - terminal foot ou kitty, thémé Orbe ;
  - shell fish avec un prompt Starship Orbe ;
  - gestionnaire de fichiers Nautilus ou Thunar ;
  - navigateur Firefox, avec un `userChrome.css` Orbe optionnel ;
  - éditeur de texte, visionneuse d'images, lecteur vidéo mpv avec un OSC thémé ;
  - captures d'écran (grim, slurp, satty), presse-papiers avec historique (cliphist) ;
  - fastfetch avec un logo Orbe en ASCII.
- **Mises à jour** : `pacman` plus un petit outil graphique (voir 3.11). Instantanés btrfs avec snapper, et entrées de démarrage sur instantané si le chargeur d'amorçage le permet.

## 3. Le bureau : Orbe Shell (inspiré de Caelestia)

Étudie le fonctionnement et l'ergonomie de Caelestia Shell : barre verticale, tableau de bord qui se déploie depuis la barre, lanceur, centre de notifications, menu de session, OSD, écran de verrouillage. Reproduis cette expérience, réécrite avec l'identité Orbe. La différence principale : Caelestia génère ses couleurs à partir du fond d'écran (Material You). Orbe garde **sa palette fixe** et un seul accent. Une option « accent depuis le fond d'écran » peut venir en bonus, désactivée par défaut.

Tous les composants sont en QML/Quickshell, dans `orbe-shell`, avec un fichier de jetons unique (`Theme.qml` : couleurs, polices, rayons, durées). Aucun code couleur ne doit être écrit en dur ailleurs que dans ce fichier.

### 3.1 Barre

- Verticale à gauche par défaut, avec un réglage pour la passer en barre horizontale en haut.
- Contenu de haut en bas :
  - logo orbe (ouvre le lanceur) ;
  - espaces de travail (indicateur actif en accent, occupés en `text`, vides en `line`) ;
  - fenêtre active (icône) ;
  - zone de notifications système (tray) ;
  - indicateurs réseau, Bluetooth, son, batterie si portable ;
  - horloge en JetBrains Mono ;
  - bouton de session.
- Survol ou clic sur un module : un panneau détaillé glisse depuis la barre, avec l'animation Orbe.
- Multi-écran : une barre par écran, espaces de travail propres à chaque écran.

### 3.2 Tableau de bord (déployé depuis la barre)

Onglets :
- **Accueil** : heure et date en grand, météo (Open-Meteo, sans clé API, ville réglable), calendrier du mois, lecteur multimédia (MPRIS : pochette, titre, contrôles, barre de progression).
- **Système** : CPU, RAM, GPU (NVIDIA et AMD), températures, disques, réseau, en graphes sobres tracés en accent.
- **Média** : lecteur détaillé avec visualiseur audio (cava) en barres citron.

### 3.3 Lanceur d'applications

- Ouvert avec la touche Super. Recherche floue sur les applications.
- Préfixes :
  - `>` commandes ;
  - `=` calculatrice ;
  - `:` emojis ;
  - `/` actions (éteindre, verrouiller, changer de fond d'écran, thème) ;
  - recherche de fichiers.
- Navigation complète au clavier. L'élément sélectionné porte l'anneau de focus Orbe.

### 3.4 Notifications

- Bulles empilées en haut à droite, avec actions et images, et fermeture par glissement.
- Centre de notifications avec historique et mode « ne pas déranger ».

### 3.5 Réglages rapides

Wi-Fi, Bluetooth, son (sortie, entrée, volume par application), luminosité, mode nuit (hyprsunset), profil d'énergie, ne pas déranger.

### 3.6 OSD

Volume, luminosité et verrouillage majuscules : une petite jauge en accent, au bord de l'écran.

### 3.7 Menu de session

Verrouiller, se déconnecter, mettre en veille, redémarrer, éteindre. Le bouton éteindre est en `danger`. Plein écran assombri, avec l'orbe au centre.

### 3.8 Écran de verrouillage

- Hyprlock ou un écran Quickshell (protocole ext-session-lock).
- Contenu : orbe de particules animé, heure en grand, champ de mot de passe avec l'anneau de focus, média en cours.
- Veille automatique avec hypridle.

### 3.9 Fond d'écran

- Sélecteur intégré. Fonds fournis : générés par toi (orbe, grilles, dégradés noirs avec halo citron), sans aucune image protégée.
- Fond animé « orbe vivant » (shader ou rendu QML) qui se met en pause sur batterie et quand une fenêtre est en plein écran.

### 3.10 Coins et bords

Coins d'écran arrondis façon Caelestia, et un effet de bordure de cadre autour du bureau, réglable ou désactivable.

### 3.11 Application « Réglages Orbe »

- Écrite en QML, elle utilise le même thème.
- Réglages couverts :
  - apparence : barre gauche ou haut, animations, coins, fond ;
  - écrans : résolution, échelle, disposition ;
  - clavier : disposition FR AZERTY par défaut ;
  - souris et pavé tactile ;
  - son, réseau, Bluetooth ;
  - utilisateurs ;
  - mises à jour : liste des mises à jour pacman, bouton « tout mettre à jour », instantané snapper avant ;
  - à propos : logo, version, matériel.
- Les réglages sont écrits dans des fichiers de configuration lisibles (`~/.config/orbe/…`) et rechargés à chaud.

### 3.12 Raccourcis clavier

- Cohérents et documentés, avec un écran d'aide (Super + /) qui liste tous les raccourcis.
- Base : Super pour le lanceur ; Super + Entrée pour le terminal ; Super + Q pour fermer ; Super + 1 à 9 pour les espaces de travail ; Super + V pour le presse-papiers ; Super + Maj + S pour la capture ; Super + L pour verrouiller ; Super + D pour le tableau de bord.

### 3.13 Fenêtres Hyprland

- Bordure active en accent, bordure inactive en `line`.
- Espacements modérés, flou léger sur les panneaux du shell seulement.
- Animations Orbe : courbe `.2,.8,.2,1`, ouverture en fondu avec une légère mise à l'échelle.

### 3.14 Performance

- Le shell au repos ne doit pas dépasser environ 2 % de CPU, et l'animation de l'orbe doit pouvoir être coupée.
- Mesure la consommation et note-la dans le journal.

## 4. Thème global (tout doit être Orbe)

- **GTK 3 et 4 / libadwaita** : thème de couleurs Orbe (`gtk.css` avec les couleurs nommées libadwaita, plus adw-gtk3 pour GTK 3).
- **Qt 5 et 6** : qt6ct, ou Kvantum avec un thème Orbe.
- **Icônes** : un jeu existant sous licence libre (Papirus, par exemple), avec les dossiers recolorés en accent. Plus un jeu d'icônes Orbe maison pour le shell (traits fins, style monoligne).
- **Curseur** : thème de curseur Orbe (noir, contour blanc cassé, point citron), en hyprcursor et en xcursor.
- **Démarrage** :
  - GRUB ou systemd-boot thémé (choisis-en un et justifie) ;
  - Plymouth avec l'orbe de particules qui se forme ;
  - le menu de l'ISO live (syslinux et GRUB) thémé lui aussi.
- **Terminal** :
  - palette Orbe dans foot ou kitty, fish et Starship ;
  - `LS_COLORS`, bat et btop thémés ;
  - Neovim ou micro avec un thème Orbe si c'est simple.
- **Sons système** : courts et sobres. Pars des sons générés pour Orbe Launcher s'ils conviennent.
- **Branding** :
  - `/etc/os-release` : NAME="Orbe OS", ID=orbe, ID_LIKE=arch ;
  - logo SVG et PNG à plusieurs tailles ;
  - logo pour fastfetch ;
  - fond de l'installateur.
- **Orbe Launcher** : prévois l'intégration (une entrée « Mode jeu » qui ouvre le launcher en plein écran). Le launcher est surtout pensé pour Windows aujourd'hui : analyse ce qu'il faudrait pour une version Linux et fais-moi un rapport. Ne le modifie pas sans mon accord.

## 5. Installation

- **Installateur graphique** : Calamares, thémé Orbe, avec branding et diaporama.
  - Choix :
    - disque : effacement complet ou manuel ;
    - système de fichiers : btrfs avec sous-volumes et snapper par défaut, ou ext4 ;
    - chiffrement LUKS en option ;
    - utilisateur ;
    - fuseau horaire Europe/Paris et clavier FR par défaut ;
    - pilotes NVIDIA ;
    - noyau LTS ou non.
  - Les paquets viennent du dépôt `[orbe]` embarqué dans l'ISO, et la synchronisation avec les miroirs Arch se fait si le réseau est disponible.
- Une option `archinstall` avec un profil Orbe (fichier de config JSON) pour l'installation en mode texte.
- Après installation : premier démarrage sur le greeter Orbe, puis un **assistant de bienvenue** (QML) qui propose :
  - le fond d'écran ;
  - la barre gauche ou haut ;
  - la ville pour la météo ;
  - les applications optionnelles (Steam, Discord, VS Code, OBS, LibreOffice) à cocher ;
  - un lien vers l'aide des raccourcis.

## 6. Organisation du dépôt

```
orbe-os/
  README.md            présentation, captures, comment construire, licences
  JOURNAL.md           fait / à faire / décisions, tenu à jour
  build.sh             construit les paquets puis l'ISO dans Docker
  test.sh              lance l'ISO ou un disque installé dans QEMU (UEFI + BIOS)
  archiso/             profil archiso (packages.x86_64, airootfs, profiledef.sh)
  packages/            un dossier par PKGBUILD (orbe-shell, orbe-themes, ...)
  shell/               source QML d'Orbe Shell (Theme.qml unique)
  themes/              gtk, qt, kvantum, icônes, curseur, plymouth, grub, terminal
  calamares/           config et branding de l'installateur
  wallpapers/          sources et rendus
  docs/                raccourcis, architecture, captures
  LICENSES/
```

## 7. Étapes et critères de validation

Ne passe à l'étape suivante que quand la précédente est validée et commitée. À chaque étape, fais des captures dans QEMU (`grim` dans la session, ou capture QEMU) et regarde-les toi-même pour vérifier le rendu.

1. **Construction de base** : `build.sh` produit une ISO Arch qui démarre dans QEMU en UEFI et en BIOS, avec le dépôt `[orbe]` vide branché. Validé quand l'ISO démarre jusqu'à un shell.
2. **Session live graphique** : Hyprland et Quickshell démarrent automatiquement dans le live. Validé quand le bureau s'affiche dans QEMU (virtio-gpu avec GL), le clavier est en AZERTY et le terminal s'ouvre.
3. **Orbe Shell, premier jet** : barre, lanceur, notifications, OSD, menu de session et `Theme.qml`. Validé quand chaque composant marche au clavier et à la souris et que les captures montrent la palette respectée.
4. **Tableau de bord, réglages rapides, écran de verrouillage, fonds d'écran.**
5. **Thème global** : GTK, Qt, icônes, curseur, terminal, Plymouth, chargeur d'amorçage. Validé quand une application GTK 4, une application Qt et le terminal ont l'air de faire partie du même système.
6. **Installateur Calamares** : installation complète sur un disque virtuel (btrfs, avec chiffrement et sans), redémarrage, greeter, puis assistant de bienvenue. Validé quand les deux scénarios passent de bout en bout.
7. **Application Réglages Orbe et outil de mises à jour.**
8. **Finitions** :
   - accessibilité : contraste, navigation clavier partout, réduction des animations ;
   - performance mesurée ;
   - README avec captures ;
   - liste des licences.
9. **Test sur vrai matériel** : écris-moi un guide (Ventoy ou `dd`) et une liste de points à vérifier, en particulier NVIDIA RTX 3050, double écran, Wi-Fi et veille. Je ferai le test moi-même.

## 8. Ce que je veux à la fin

- Une ISO `orbe-os-AAAA.MM.JJ-x86_64.iso` construite par une seule commande.
- Un bureau qui donne l'impression d'un produit fini et cohérent : même palette, mêmes polices, mêmes rayons et mêmes animations partout, du menu de démarrage jusqu'à la fenêtre de réglages.
- Un `JOURNAL.md` honnête : ce qui marche, ce qui n'a été testé qu'en machine virtuelle, ce qui reste à faire, les limites connues.

Commence par :
- lire la documentation d'archiso, de Quickshell et de Caelestia Shell ;
- vérifier dans quels dépôts se trouvent Quickshell et les autres paquets clés ;
- me proposer un plan court avec tes choix (greeter, chargeur d'amorçage, terminal, gestionnaire de fichiers), chacun justifié en une ligne.

Attends ma validation avant d'écrire du code.
