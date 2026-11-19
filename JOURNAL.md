# Journal Orbe OS

Tenu à jour à chaque étape : ce qui est fait, ce qui reste, les décisions et les limites. « VM » signifie testé seulement dans QEMU, « réel » sur un vrai PC.

## Où en est le projet

| Étape | État |
|---|---|
| 1. Construction de base | validée en VM (UEFI + BIOS), 2026-11-17 |
| 2. Session live graphique | validée en VM, 2026-11-18 |
| 3. Orbe Shell, premier jet | validée (banc d'essai + VM), 2026-11-18 |
| 4. Tableau de bord, réglages rapides, verrouillage, fonds | validée (banc d'essai + VM), 2026-11-18 |
| Mode jeu (demande de Yass) | fait ; bascule bureau ↔ jeu validée en VM, Steam et gamescope à tester sur matériel |
| 5. Thème global | validée en VM et sur le banc d'essai, 2026-11-18 (sauf l'écran Plymouth, invisible en VM : à vérifier sur matériel) |
| 6. Installateur Calamares | validée en VM, 2026-11-19 : btrfs sans chiffrement et btrfs + LUKS2, installation, redémarrage, écran de connexion, assistant |
| 7. Réglages Orbe et mises à jour | faite : application vérifiée sur le banc d'essai (toutes les pages), `orbe-update` ; à essayer en vrai avec Internet |
| 8. Finitions | faite pour l'essentiel : contraste AA, navigation au clavier, réduction des animations, processeur mesuré, aide des raccourcis, presse-papiers, README avec captures, licences ; restent les points listés plus bas |
| 9. Test sur vrai matériel | guide prêt (`docs/test-materiel.md`), test par Yass |

## Décisions

### 2026-11-17
- **Machine de construction : session Claude dans le cloud** (conteneur Ubuntu 24.04, 4 cœurs Xeon, 16 Go, sans `/dev/kvm` ni GPU), à la place du PC Windows/WSL2 prévu. Yass a demandé d'avancer. Conséquences : QEMU tourne en émulation logicielle (TCG), lente, et sans accélération 3D réelle. Le rendu final se vérifiera sur le PC de Yass.
- **Orientation donnée par Yass** : un OS polyvalent qui démarre sur le plus de machines possible, bien optimisé une fois installé sur son PC, puis distribuable pour équiper plusieurs PC orientés jeu. D'où, dès l'étape 1 : dépôt `multilib` activé (Steam, Proton, pilotes 32 bits).
- **Choix appliqués par défaut** (propositions de `docs/ETAT.md`, Yass a dit de continuer) : GRUB (BIOS + UEFI, instantanés btrfs), greetd + greeter Quickshell, foot, Nautilus, verrouillage Quickshell, shell réécrit sans code de Caelestia. Chacun reste modifiable.
- **Licence du code Orbe : MIT** (choix de Yass le 2026-11-18), comme Orbe Launcher. Fichier `LICENSE` à la racine, paquets `[orbe]` en `MIT`.
- **ISO** : `uefi.grub` (x64 et IA32 mixte) + `bios.syslinux`, squashfs en zstd (niveau 19, niveau 3 avec `--fast`) : décompression plus rapide que xz, donc session live plus réactive.
- **Image de construction** : `archlinux:latest`. Si Docker Hub refuse (limite de 429 rencontrée ici), `build.sh` importe l'archive bootstrap officielle d'Arch après vérification de sa somme SHA-256.
- **Menus syslinux** : écrits en UTF-8 dans le dépôt, convertis en CP437 au moment du build (syslinux n'affiche que ce jeu de caractères).
- **Langue et clavier du live** : `fr_FR.UTF-8` (avec `en_US.UTF-8` généré), clavier console `fr`.
- **Thème des menus de démarrage avancé** (demande de Yass) : GRUB et syslinux de l'ISO habillés Orbe dès maintenant, au lieu de l'étape 5. L'orbe reprend le style de `orb.webp` d'Orbe Launcher (points blanc cassé translucides, environ 10 % de points citron plus gros), redessiné par `themes/boot/generate.py`, sans image externe.
- **GRUB en 1920x1080** (`gfxmode=1920x1080,1280x720,auto`) : la mise en page est faite pour cette définition, que presque tous les écrans de PC de jeu proposent en UEFI. Les polices GRUB ne s'adaptent pas à la définition, d'où ce choix plutôt que la définition native (texte minuscule en 4K).
- **Polices GRUB générées au build** (`tools/make-grub-fonts.sh`) depuis Archivo (graisses 400 et 600 figées avec fontTools) et JetBrains Mono, plutôt que versionnées.
- **Hyprland 0.57 se configure en Lua** (`hyprland.lua`, API `hl.*`), plus en `hyprland.conf`. Vérifié dans le paquet (exemple et définitions de `/usr/share/hypr/stubs`) et dans le wiki versionné `wiki.hypr.land/0.57.0/`. La configuration Orbe est découpée en modules dans `/usr/share/orbe/hypr/` (paquet `orbe-desktop`), chargés par un petit `~/.config/hypr/hyprland.lua` personnel : les mises à jour d'Orbe s'appliquent sans écraser les réglages de l'utilisateur.
- **Paquet supplémentaire `orbe-desktop`** (hors liste du cahier des charges) : dépendances de la session, configuration Hyprland et fichiers de `/etc/skel`. `orbe-shell` ne contient que le QML, `orbe-themes` les polices et palettes.
- **Souris sans accélération** (`accel_profile = flat`) par défaut, VRR en plein écran (`vrr = 2`) et tearing autorisé pour les jeux qui le demandent : choix orientés jeu, modifiables dans `~/.config/hypr/hyprland.lua`.
- **Session live** : utilisateur `orbe` sans mot de passe (sudo sans mot de passe), ouverture automatique de Hyprland par greetd (`initial_session`), fuseau Europe/Paris.
- **NVIDIA dans le live** : `nvidia-open` embarqué. Au démarrage, `orbe-gpu-setup` charge le pilote NVIDIA si une carte NVIDIA est présente et le pilote la prend en charge, sinon `nouveau`. Entrée de menu « avec pilotes libres » (`orbe.gpu=libre`) en secours. **Non testé** : la VM n'a pas de carte NVIDIA.
- **Banc d'essai du shell** (`tools/shell-preview.sh`) : Quickshell lancé depuis `shell/` dans sway sans écran (rendu logiciel), capture en quelques secondes, sans reconstruire l'ISO. Il a trouvé la première erreur : une propriété QML nommée `onAccent` est prise pour un gestionnaire de signal, renommée `textOnAccent`.
- **Rendu 3D en VM sans GPU** : QEMU `egl-headless` exige un nœud DRM absent ici. `test.sh --xvfb --gl` lance un écran X virtuel (Xvfb) et QEMU en SDL avec virgl, rendu par llvmpipe sur le processeur.
- **Direction « SteamOS nouvelle génération »** (Yass) : mode jeu plein écran pour la manette, optimisations de jeu, interface soignée. Proposition détaillée et choix à valider dans `docs/mode-jeu.md`.

### 2026-11-18
- **Sauvegarde GitHub** : dépôt privé `Yasder5/orbe-os` créé par Yass, historique rebasé sur son commit initial (sa `LICENSE` MIT est gardée), poussé avec son accord.
- **Orbe Shell, organisation** : jetons dans `Theme.qml` seulement, réglages utilisateur dans `~/.config/orbe/shell.json` (rechargés à chaud), services en singletons, commandes IPC pour les raccourcis. Détails et pièges dans `docs/shell.md`.
- **Lanceur rattaché à la barre** : il sort de derrière la barre (comme les autres panneaux), plutôt qu'au centre de l'écran. Préfixes `>` commande, `=` calcul, `:` émoji (noms Unicode + mots-clés français), `/` actions, `~` fichiers. Classement par usage, gardé dans l'état de Quickshell.
- **Terminal stylé, avancé depuis l'étape 5** (demande de Yass) : fish par défaut, invite Starship Orbe, fastfetch avec l'orbe en ASCII au premier terminal de la session, eza (icônes et colonne git), bat (thème ANSI, donc la palette du terminal), btop au thème Orbe, police de symboles Nerd Font en secours.
- **Banc d'essai du shell amélioré** : D-Bus de session, rendu OpenGL sur processeur (llvmpipe) pour les halos et ombres, frappe au clavier (wtype), terminal.

### 2026-11-18 (étape 4)
- **Orbe en shader** (`shell/shaders/orb.frag`) : pour chaque pixel, la particule la plus proche est retrouvée en temps constant par l'inverse de la répartition de Fibonacci (Keinert et al., 2015). Le processeur ne fait plus qu'avancer un angle. Le shader est compilé en `.qsb` au build (`tools/build-shaders.sh`, `qt6-shadertools`). Remplace le Canvas qui saturait le processeur émulé.
- **Fonds d'écran générés** (`wallpapers/generate.py`, paquet `orbe-wallpapers`) : orbe, orbe au centre, grille, halo, en 3840x2160. Fond « Orbe vivant » dessiné en direct, à 30 images/s au plus, en pause sur batterie et quand une fenêtre est en plein écran. Le fond d'écran existant de Yass (`orbe-paysage.png`) n'est pas embarqué sans son accord.
- **Verrouillage** : Quickshell (ext-session-lock) et PAM (`shell/lock/pam/orbe-lock`), hypridle pour la veille (5 min écran assombri, 10 min verrouillage, 11 min écran éteint, 30 min mise en veille), jamais en plein écran (règle `idle_inhibit`), désactivé dans la session live où le compte `orbe` a un mot de passe vide.
- **Live : NetworkManager et BlueZ** à la place d'iwd et systemd-networkd, pour les réglages rapides.
- **Espaces de travail par écran** : l'écran n utilise les espaces n×10+1 à n×10+9 (`workspaces.lua`), chaque barre affiche les siens.
- **Heroic Games Launcher** (Epic, GOG, Amazon) : paquet officiel `-bin` reconstruit dans `[orbe]`, thème CSS Orbe (`themes/heroic/orbe.css`) et français écrits au premier lancement (`orbe-first-login`, chemins absolus du compte). Les paquets venant de l'AUR sont optionnels : si leur source est injoignable, le build continue sans eux (`archiso/packages.optional`).
- **Steam Big Picture aux couleurs d'Orbe** : le skin de Yass passe par CSS Loader (Decky Loader). Prévu avec le mode jeu, qui en a besoin de toute façon.

### 2026-11-18 (mode jeu, étapes 5 à 8)
- **Mode jeu** (`packages/orbe-gaming`, `docs/mode-jeu.md`) : `orbe-session` lancé par greetd ouvre la dernière session (bureau ou jeu), `orbe-switch-session` bascule (hyprshutdown ferme d'abord les applications proprement), Steam appelle `steamos-session-select` pour revenir au bureau. Si Steam se ferme seul, retour au bureau : jamais d'écran noir.
- **Thème Steam** : Decky Loader et CSS Loader empaquetés depuis leurs **binaires officiels** (les archives de sources GitHub de ces dépôts sont bloquées ici ; seules les pièces jointes des versions passent). Thème d'Orbe Launcher activé au premier lancement du mode jeu.
- **`lib32-nvidia-utils` hors de l'ISO** (576 Mo installé) : installé par l'installateur si une carte NVIDIA est là et qu'Internet répond. `scx-scheds` (154 Mo) en option, pas dans l'ISO.
- **GTK** : adw-gtk3-dark + couleurs libadwaita Orbe (`@define-color` et variables CSS de libadwaita 1.6+), incluses par `@import` depuis `~/.config/gtk-*/gtk.css`, donc mises à jour avec le paquet. **Qt** : qt6ct, style Fusion, palette Orbe et retouches QSS (Kvantum pas retenu : Fusion suffit et reste léger).
- **Icônes** : Papirus-Dark, dossiers recolorés en citron par script au build (paquet `orbe-icon-theme`, GPL-3.0 comme Papirus). **Curseur Orbe** dessiné par script (14 formes, 93 alias), en xcursor et hyprcursor, dans le même thème « Orbe » que les icônes.
- **Plymouth** : thème script, l'orbe se forme (36 images) puis tourne (90 images), champ de mot de passe pour le disque chiffré.
- **Identité** : `/usr/lib/os-release`, `/etc/lsb-release` et `/etc/issue` réécrits par un hook pacman après chaque mise à jour de `filesystem` (ces fichiers appartiennent aux paquets d'Arch).
- **Sons** : ceux d'Orbe Launcher (MIT) en thème freedesktop `orbe` ; Orbe Shell joue la notification et le réglage du volume (réglage `sounds`).
- **Installateur** : Calamares 3.4.2 reconstruit depuis la recette AUR. Copie du live (pas de téléchargement), module Python `orbe` pour nettoyer la copie. Partition EFI sur `/boot` pour que GRUB n'ait jamais à lire le disque chiffré (LUKS2/argon2). btrfs + snapper + snap-pac + grub-btrfs par défaut.
- **Greeter, assistant, Réglages et aide intégrés à Orbe Shell** (mêmes `Theme.qml` et composants) plutôt qu'en applications séparées : `greeter.qml` (lancé dans cage par greetd), `welcome/`, `settings/`, `help/`.
- **Réglages de Hyprland faits dans l'application** : écrits en Lua dans `~/.config/orbe/hyprland.lua`, chargé à la fin de la configuration Orbe, puis `hyprctl reload`. Le clavier choisi à l'installation est lu dans `/etc/X11/xorg.conf.d/00-keyboard.conf`.
- **Pas de navigateur dans l'ISO** (taille) : Firefox est coché par défaut dans l'assistant de bienvenue.

## Mesures
- **Orbe Shell au repos** (banc d'essai, fond fixe, rendu logiciel) : **0,2 % d'un cœur**, objectif de 2 % tenu. Mémoire 330 Mo, gonflée par le rendu logiciel (llvmpipe). Un orbe animé plein écran rendu par le processeur (VM sans GPU) prend un cœur entier : c'est pourquoi le fond par défaut est fixe ; sur une vraie carte graphique, le shader ne coûte presque rien au processeur (à confirmer sur le PC de Yass).
- **Contraste** (WCAG) : texte `#f5f5f0` sur fond 18:1, texte secondaire `#8f8f8a` sur fond 6,1:1 et sur `surface-2` 5,4:1, noir sur citron 16,9:1, `danger` sur fond 7,1:1 : tout dépasse AA (4,5:1).
- **ISO** : 2,7 Go en compression rapide (`--fast`, zstd 3), **2,44 Gio en compression finale** (`./build.sh`, zstd 19, 9 min de construction). Au-dessus de la limite de 2 Gio par fichier des versions GitHub : **décision de Yass** pour la distribution (hébergement ailleurs, ISO découpée, ou une variante plus légère sans pilote NVIDIA ni Heroic, installés ensuite par le réseau).

## Vérifié le 2026-11-17 (dépôts Arch)
quickshell 0.3.2, hyprland 0.57.2, hyprlock 0.9.7, hypridle 0.1.8, greetd 0.10.3, archiso 92, grub 2.16, grub-btrfs 4.14, qt6-base 6.12.0, linux 7.3.4, linux-zen 7.3.4, linux-lts 6.18.63, mesa 26.2.7, nvidia-open 620.70.06, gamemode 1.8.2, gamescope 3.17.0, mangohud 0.8.4, steam (multilib). Toujours absents des dépôts officiels : calamares, ttf-archivo, hyprland-qtutils (remplacé par hyprland-guiutils, présent), nvidia-580xx-dkms.

## Limites connues
- **Secure Boot** : GRUB est construit sans shim signé. Il faut désactiver Secure Boot pour démarrer l'ISO. Une version signée demande une clé reconnue par les PC (shim signé par Microsoft) : hors de portée pour l'instant.
- **NVIDIA** : `nvidia-open` 620 ne gère que les cartes Turing et plus récentes (GTX 16xx, RTX 20xx et au-delà, dont la RTX 3050). Les GTX 9xx/10xx demandent `nvidia-580xx-dkms`, seulement dans l'AUR : à reconstruire dans `[orbe]` si on veut les prendre en charge.
- **Tests** : tout ce qui suit n'est testé qu'en VM (QEMU TCG) tant que Yass n'a pas essayé sur son PC.

## Fait
- Dépôt git créé selon la section 6 du cahier des charges.
- Profil archiso `archiso/` dérivé de releng 92 : nom, menus GRUB et syslinux en français, `[orbe]` puis `core`, `extra`, `multilib`.
- `build.sh` : une commande, conteneur Arch privilégié, cache pacman en volume, dépôt `[orbe]` (vide pour l'instant) construit puis branché, ISO `orbe-os-AAAA.MM.JJ-x86_64.iso` et sa somme SHA-256.
- `test.sh` : QEMU en UEFI ou BIOS, disque virtuel, rendu 3D optionnel, captures et touches programmées.
- **Étape 1 validée en VM** : `build.sh --fast` produit `orbe-os-2026.11.17-x86_64.iso` (1,3 Go) en 5 min environ, `[orbe]` vide synchronisé par mkarchiso. L'ISO démarre jusqu'au shell root en UEFI (GRUB) et en BIOS (syslinux), clavier `fr`, accents corrects dans les deux menus. Captures vérifiées : `out/captures/uefi-280s.png`, `bios-menu.png`, `bios-280s.png`. Démarrage jusqu'au shell en environ 4 min, en émulation TCG sans KVM.

- **Menus de démarrage thémés (VM)** : GRUB (UEFI) avec fond orbe, titre Archivo, panneau `surface` à rayon 8, élément choisi en `surface-2` avec anneau citron, icônes monolignes (Éteindre en `danger`), compte à rebours et aide clavier en JetBrains Mono. Syslinux (BIOS) : fond orbe 640x480, élément choisi sur fond citron, textes en français. Navigation au clavier vérifiée, démarrage jusqu'au shell revérifié en UEFI. Captures : `out/captures/uefi-menu.png`, `uefi-menu-fin.png`, `bios-menu.png`.

- **Étape 2 validée en VM** (QEMU TCG + virgl rendu par llvmpipe, 1920x1080) : greetd ouvre Hyprland pour `orbe` sans intervention, Orbe Shell affiche la barre (orbe, espaces de travail, horloge à l'heure de Paris), Super + Entrée ouvre foot à la palette Orbe (bordure citron, rayon 8), le texte tapé sort en AZERTY, Super + 2 (code de touche) change d'espace de travail. Le bureau apparaît environ 6 min après le menu de démarrage en émulation, ce qui ne dit rien de la vitesse réelle. Captures : `out/captures/uefi-e2-bureau.png`, `uefi-e2-azerty.png`, `uefi-e2-espace2.png`, `uefi-e2b-couleurs.png`.
- Correction trouvée en VM : foot 1.28 n'accepte plus la section `[colors]`, renommée `[colors-dark]` ; la configuration est maintenant vérifiée par `foot --check-config`.

- **Étape 3 validée** : chaque composant vérifié sur le banc d'essai (captures `out/captures/shell-*.png`) et dans l'ISO en VM : Super seul ouvre le lanceur, la recherche lance foot, `notify-send` arrive dans les bulles et le centre (pastille sur la cloche), Super + Échap ouvre le menu de session. Calcul vérifié (`(12+3)*4^2` donne 240), recherche d'émojis en français (`:coeur`).
- **Terminal en VM** : fastfetch Orbe, fish et Starship dans la vraie session Hyprland (capture `out/captures/uefi-e3-terminal.png`).

- **Étape 4 validée** : sur le banc d'essai, chaque panneau (tableau de bord et ses trois onglets, réglages rapides, sélecteur de fonds, verrouillage) ; dans l'ISO en VM : fond Orbe et barre (indicateur réseau), Super + D ouvre le tableau de bord, Super + L verrouille (orbe en shader, heure, champ avec anneau de focus), Entrée déverrouille le compte live, Heroic s'ouvre avec le thème Orbe (Archivo, accent citron, interface en français). Captures : `out/captures/uefi-e4-*.png`, `shell-e4-*.png`.
- Super + A n'a pas été vérifié en VM : la commande de test envoie des positions de touches QWERTY, et la touche A de l'AZERTY est le Q du QWERTY (Super + Q ferme la fenêtre). Vérifié sur le banc d'essai.

- **Mode jeu en VM** : Super + G ferme la session Hyprland, `orbe-session` tente le mode jeu (gamescope ne démarre pas sans carte graphique Vulkan), puis revient au bureau. zram actif, Decky Loader démarré. Captures `out/captures/uefi-jeu-*.png`.
- **Étape 5 en VM** : fastfetch affiche « Orbe OS », Nautilus (GTK 4) et foot assortis (fond, police, bordure citron), curseur Orbe. Sur le banc d'essai : greeter, assistant de bienvenue, Réglages Orbe, aide des raccourcis.
- **Installation en VM (btrfs, sans chiffrement)** : assistant live, Entrée lance Calamares aux couleurs d'Orbe, pages Bienvenue, Emplacement (Europe/Paris), Clavier (français), Partitions (effacer le disque, 2 Go FAT32 sur `/boot` + 62 Go btrfs), Utilisateurs, Résumé, installation (37 min en émulation, surtout la copie), « Installation terminée ». Au redémarrage sur le disque : menu GRUB Orbe, écran de connexion Orbe avec le compte créé, connexion, assistant de bienvenue. Captures `out/captures/uefi-i-*.png` et `uefi-d-*.png`.
- **Installation chiffrée en VM (btrfs + LUKS2)** : la case « Chiffrer le système » et la phrase de passe passent au clavier, Calamares crée 2 Go FAT32 sur `/boot` + 62 Go LUKS2, installation terminée. Au démarrage, la phrase de passe tapée ouvre le disque et l'écran de connexion Orbe s'affiche. Captures `out/captures/uefi-e-*.png`, `uefi-f-*.png`.
- **Contrôle du disque installé** (monté depuis un conteneur) : hooks `base udev autodetect microcode kms modconf block keyboard keymap consolefont plymouth filesystems`, thème Plymouth `orbe`, `splash` au démarrage, greetd sur le greeter Orbe, configuration snapper `root` et `/.snapshots` dans fstab, `os-release` « Orbe OS », plus de `sudoers.d/orbe-live`, `decky-loader@yass` et `grub-btrfsd` activés. Le menu GRUB installé a bien le thème Orbe et l'entrée « Orbe OS snapshots ».
- **Plymouth jamais visible en VM**, ni dans le live ni installé : l'image reste celle de GRUB jusqu'au pilote graphique, puis noir pur (pas le noir Orbe). En émulation, la minuterie de GRUB et l'affichage précoce sont peu fiables ; ajouté `plymouth.use-simpledrm` (écran de démarrage sur le tampon d'image du micrologiciel, recommandé pour NVIDIA, dont le pilote n'est pas dans l'initramfs). **À vérifier sur le PC de Yass.**
- GRUB installé : les entrées « EFI BootNext » de GRUB 2.16 (une par entrée du micrologiciel) masquées, variantes de démarrage dans un sous-menu.
- Corrigé après ce test : l'assistant perdait le focus clavier après l'étape Météo (et la touche Entrée y décochait Firefox) ; le diaporama de Calamares avait un cadre blanc.
- En VM, Orbe Shell met parfois plus de 5 min à apparaître : il attend des réponses D-Bus (UPower, power-profiles-daemon, BlueZ) qui expirent au bout de 25 s en émulation lente. Pas d'erreur dans son journal ; à surveiller sur matériel réel.

## À faire
- Météo : non vérifiée ici (Open-Meteo n'est pas joignable depuis ce conteneur). Affiche « Météo indisponible » hors ligne.
- Consommation du shell et de l'orbe animé à mesurer sur le PC de Yass (objectif : 2 % au repos).
- Heroic affiche au premier lancement sa question sur les statistiques anonymes : laissée à l'utilisateur.
- `loopback.cfg` (démarrage de l'ISO depuis un autre GRUB, Ventoy en mode GRUB par exemple) garde le menu texte, avec l'écran Plymouth.
- **Dépôt `[orbe]` hébergé** : décision de Yass (voir `docs/installation.md`). Sans lui, les paquets Orbe d'un système installé ne se mettent pas à jour.
- Page « Options » de l'installateur (noyaux LTS et Zen) : non testée, la VM n'a pas d'accès à Internet pour pacman.
- Le menu GRUB installé s'appelle « Orbe OS Linux » (GRUB ajoute « Linux » au nom de la distribution).
- Instantanés btrfs : le noyau est sur la partition EFI, hors des instantanés. Démarrer un instantané pris avant une mise à jour du noyau peut échouer (modules d'une autre version) : à documenter ou corriger (copie du noyau dans l'instantané).
- `xpadneo` (manettes Xbox en Bluetooth) et `game-devices-udev` pas encore empaquetés.
- Détection NVIDIA du live (`orbe-gpu-setup`) à tester sur le PC de Yass (RTX 3050).
- Taille de l'ISO : 2,1 Go en compression rapide, à mesurer en compression finale (limite de 2 Go par fichier sur les Releases GitHub).
- Mode jeu : choix validés le 2026-11-18 (voir `docs/mode-jeu.md`). Rapport sur Orbe Launcher sous Linux : `docs/orbe-launcher-linux.md`.
- Sauvegarde : Yass crée un dépôt GitHub privé, puis premier `git push` (accord donné le 2026-11-18).
