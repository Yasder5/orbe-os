# État du projet au 2026-10-31

Aucun code écrit, aucun dépôt git créé. Seule la recherche initiale est faite.

## Machine de construction
Décision de Yass : construction et tests sur un PC gamer **sous Windows**, différent du PC Manjaro (RTX 3050, Ryzen 7 5800X) cité dans le cahier des charges, et différent du PC de la session précédente (Debian 12, sans KVM). Configuration matérielle inconnue : le préflight l'affiche.

Rien de ce qui suit n'a été testé sur ce PC :
- **Construction :** `build.sh` dans Docker, depuis WSL2. Docker dans Ubuntu (`docker.io`) ou Docker Desktop avec l'intégration WSL. Devrait marcher, à confirmer avec `mkarchiso` en conteneur privilégié.
- **Fichiers :** tout le dépôt reste dans le système de fichiers WSL (`~/orbe-os`), jamais sous `/mnt/c`.
- **`/dev/kvm` dans WSL2 :** demande la virtualisation imbriquée. Sur CPU AMD, elle exige Windows 11. Le préflight le vérifie.
- **Rendu graphique, le vrai risque :** QEMU avec `virtio-vga-gl` sous WSLg n'est pas garanti. Si le bureau ne s'affiche pas, ne contourne pas : présente ces solutions à Yass, puis note son choix dans le journal :
  - VMware Workstation ou VirtualBox côté Windows avec accélération 3D (la prise en charge de Hyprland reste à vérifier) ;
  - démarrage de l'ISO sur clé USB sur le PC réel, avec captures par `grim`, plus lent mais le plus fidèle.
- **`test.sh` :** les captures et l'étape 6 (installation sur disque virtuel) dépendent de ce choix.

## Décisions en attente de validation
Choix proposés, à présenter à Yass :
- **Greeter : greetd + greeter Quickshell**, pour réutiliser `Theme.qml` et les composants du bureau, sans thème SDDM à maintenir à part. Lancé dans un compositeur minimal (`cage` est dans `extra`).
- **Chargeur : GRUB**, seul des deux à gérer BIOS, UEFI et les entrées d'instantanés btrfs (grub-btrfs). systemd-boot ne gère que l'UEFI.
- **Terminal : foot**, léger et natif Wayland, sans dépendre du GPU.
- **Fichiers : Nautilus**, en GTK4/libadwaita, cohérent avec le thème global.
- **Verrouillage : Quickshell (ext-session-lock)**, pour l'orbe et le média avec les mêmes composants.
- **Shell : réécriture complète**, sans code repris de Caelestia.
- **Licence du code Orbe : à trancher.** MIT recommandée (comme Orbe Launcher, possible puisque rien n'est repris de Caelestia), ou GPL-3.0 si Yass veut que les dérivés restent ouverts.

## Paquets vérifiés le 2026-10-31 (image `archlinux:latest`)
- Dans `extra` : quickshell 0.3.2, hyprland 0.57.0, hyprlock 0.9.6, hypridle 0.1.8, hyprsunset 0.4.0, hyprcursor 0.1.13, greetd 0.10.3, archiso 92, adw-gtk-theme 6.5, papirus-icon-theme, kvantum, qt6ct, cava, snapper, snap-pac, grub-btrfs, limine, plymouth, satty, cliphist, grim, slurp, starship, foot, kitty, fastfetch, nautilus, thunar, gnome-text-editor, loupe, mpv, cage, nvidia-open-dkms, ttf-jetbrains-mono, xdg-desktop-portal-hyprland, power-profiles-daemon, archinstall.
- Qt 6.12.0 (qt6-base).
- **Absents des dépôts officiels :** `calamares`, `ttf-archivo`, `adw-gtk3`, `hyprland-qtutils`.

## Corrections au cahier des charges
- **Archivo n'est pas dans les dépôts Arch.** Le TTF variable (OFL) est fourni dans `reference/fonts/`, à empaqueter dans `orbe-themes`.
- **`adw-gtk3` s'appelle `adw-gtk-theme`.**
- **Calamares vient seulement de l'AUR.** Recette 3.4.2-2 (Qt6) dans `reference/aur/calamares/`. Ses dépendances ont toutes été trouvées dans les dépôts officiels : pas d'autre paquet AUR à reconstruire. À rebuilder contre le Qt courant à chaque construction de l'ISO.
- **`skins/discord/src/orbe.css` n'est pas sur GitHub** : il n'existe que dans le dépôt local de Yass (commit `8d57b6f`, en avance sur GitHub `9a7fca6`). Il est fourni dans `reference/orbe-launcher/`.

## Pièges connus
- **Boot UEFI de l'ISO :** `releng` utilise `uefi.systemd-boot`. Passer `profiledef.sh` sur `uefi.grub` et garder `bios.syslinux`. `mkarchiso` v92 reconnaît `uefi.grub` (vérifié dans le script), le démarrage réel reste à tester.
- **Chiffrement :** GRUB gère mal LUKS2 avec argon2. Si `/boot` est chiffré, prévoir pbkdf2 ou un `/boot` séparé selon le besoin de restauration des instantanés. C'est le point le plus risqué de l'étape 6, à tester en premier.
- **Quickshell :** projet jeune, avec des ruptures d'API annoncées par sa doc. Le paquet `extra` évolue avec Arch : cibler cette version et, si une mise à jour casse le shell, reconstruire une révision figée dans `[orbe]`. Caelestia exige `quickshell-git` et des plugins compilés : ne pas supposer que son code QML tourne sur la version de `extra`.
- **Dépôt `[orbe]` :** s'il reste seulement dans l'ISO, les systèmes installés ne reçoivent aucune mise à jour Orbe alors qu'Arch continue d'avancer. Un dépôt hébergé sera nécessaire : en parler à Yass à l'étape 6, rien ne se publie sans son accord.
- **AZERTY :** lier `Super + 1 à 9` aux codes de touches (`code:10` à `code:18`), car les chiffres demandent Maj. `/` étant sur Maj + `:`, l'aide devient `Super + Maj + :` sur ce clavier.
- **Espaces de travail par écran :** Hyprland partage la numérotation entre écrans par défaut. Il faut une logique dédiée (décalage par écran, par exemple) sans dépendre d'un plugin si possible.
- **VM et NVIDIA :** le rendu GL de QEMU sur un hôte NVIDIA propriétaire n'a pas été testé. Essayer `-device virtio-vga-gl -display gtk,gl=on`, puis `sdl,gl=on` si besoin. Ce rendu reste différent du matériel réel, d'où l'étape 9.
- **`mkarchiso` :** à lancer dans un conteneur `--privileged`.

## Non vérifié
- Toute la documentation du wiki Arch sur archiso : le wiki bloque l'accès automatique (protection Anubis). Le profil `releng` du paquet a servi de référence.
- La syntaxe de configuration de Hyprland 0.57 : à contrôler avant d'écrire la configuration.
- Le rendu de Quickshell 0.3.2 sous Qt 6.12, Calamares sous Qt 6.12, et tout démarrage réel.
- Le jeu de modules Calamares à garder : la recette AUR en exclut certains (`dracut`, `initramfs`, `packagechooser`…). À vérifier avant de concevoir l'installateur, surtout `packagechooser`, utile pour NVIDIA et le noyau LTS.

## Références en ligne
- Caelestia Shell (GPL-3.0, lecture seule) : https://github.com/caelestia-dots/shell
- Quickshell : https://quickshell.org/docs/
- Orbe Launcher : https://github.com/Yasder5/orbe-launcher
- Calamares (développement sur Codeberg) : https://aur.archlinux.org/packages/calamares
