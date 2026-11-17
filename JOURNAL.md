# Journal Orbe OS

Tenu à jour à chaque étape : ce qui est fait, ce qui reste, les décisions et les limites. « VM » signifie testé seulement dans QEMU, « réel » sur un vrai PC.

## Où en est le projet

| Étape | État |
|---|---|
| 1. Construction de base | validée en VM (UEFI + BIOS), 2026-11-17 |
| 2. Session live graphique | à faire |
| 3. Orbe Shell, premier jet | à faire |
| 4. Tableau de bord, réglages rapides, verrouillage, fonds | à faire |
| 5. Thème global | à faire |
| 6. Installateur Calamares | à faire |
| 7. Réglages Orbe et mises à jour | à faire |
| 8. Finitions | à faire |
| 9. Test sur vrai matériel | à faire (par Yass) |

## Décisions

### 2026-11-17
- **Machine de construction : session Claude dans le cloud** (conteneur Ubuntu 24.04, 4 cœurs Xeon, 16 Go, sans `/dev/kvm` ni GPU), à la place du PC Windows/WSL2 prévu. Yass a demandé d'avancer. Conséquences : QEMU tourne en émulation logicielle (TCG), lente, et sans accélération 3D réelle. Le rendu final se vérifiera sur le PC de Yass.
- **Orientation donnée par Yass** : un OS polyvalent qui démarre sur le plus de machines possible, bien optimisé une fois installé sur son PC, puis distribuable pour équiper plusieurs PC orientés jeu. D'où, dès l'étape 1 : dépôt `multilib` activé (Steam, Proton, pilotes 32 bits).
- **Choix appliqués par défaut** (propositions de `docs/ETAT.md`, Yass a dit de continuer) : GRUB (BIOS + UEFI, instantanés btrfs), greetd + greeter Quickshell, foot, Nautilus, verrouillage Quickshell, shell réécrit sans code de Caelestia. Chacun reste modifiable.
- **Licence du code Orbe : pas encore tranchée.** MIT proposée. Aucun fichier `LICENSE` tant que Yass n'a pas choisi.
- **ISO** : `uefi.grub` (x64 et IA32 mixte) + `bios.syslinux`, squashfs en zstd (niveau 19, niveau 3 avec `--fast`) : décompression plus rapide que xz, donc session live plus réactive.
- **Image de construction** : `archlinux:latest`. Si Docker Hub refuse (limite de 429 rencontrée ici), `build.sh` importe l'archive bootstrap officielle d'Arch après vérification de sa somme SHA-256.
- **Menus syslinux** : écrits en UTF-8 dans le dépôt, convertis en CP437 au moment du build (syslinux n'affiche que ce jeu de caractères).
- **Langue et clavier du live** : `fr_FR.UTF-8` (avec `en_US.UTF-8` généré), clavier console `fr`.
- **Thème des menus de démarrage avancé** (demande de Yass) : GRUB et syslinux de l'ISO habillés Orbe dès maintenant, au lieu de l'étape 5. L'orbe reprend le style de `orb.webp` d'Orbe Launcher (points blanc cassé translucides, environ 10 % de points citron plus gros), redessiné par `themes/boot/generate.py`, sans image externe.
- **GRUB en 1920x1080** (`gfxmode=1920x1080,1280x720,auto`) : la mise en page est faite pour cette définition, que presque tous les écrans de PC de jeu proposent en UEFI. Les polices GRUB ne s'adaptent pas à la définition, d'où ce choix plutôt que la définition native (texte minuscule en 4K).
- **Polices GRUB générées au build** (`tools/make-grub-fonts.sh`) depuis Archivo (graisses 400 et 600 figées avec fontTools) et JetBrains Mono, plutôt que versionnées.

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

## À faire
- `loopback.cfg` (démarrage de l'ISO depuis un autre GRUB, Ventoy en mode GRUB par exemple) garde le menu texte.
- Le thème GRUB du système installé viendra avec `orbe-themes` (étape 5), à partir des mêmes fichiers.
- `/etc/os-release` et l'invite de connexion affichent encore « Arch Linux » : branding prévu dans `orbe-branding`.
