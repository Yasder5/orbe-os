# Installation d'Orbe OS

## Installateur graphique (Calamares)

« Installer Orbe OS » dans la session live : assistant de bienvenue, lanceur (taper « installer »), ou `orbe-install` dans un terminal. Configuration et habillage dans `calamares/` (paquet `orbe-installer`).

| Étape | Choix d'Orbe OS |
|---|---|
| Bienvenue | vérifie l'espace disque (24 Go), la mémoire (2 Go) et les droits ; Internet n'est pas obligatoire |
| Langue et fuseau | français, Europe/Paris par défaut |
| Clavier | AZERTY par défaut (déduit de la langue) |
| Disque | effacer le disque (défaut) ou partitionnement manuel ; **btrfs** (défaut) ou ext4 ; **chiffrement LUKS2** en option ; table GPT |
| Compte | nom, identifiant, mot de passe (aussi celui de sudo) ; ouverture automatique au choix ; shell fish |
| Options | noyau LTS (secours), noyau Zen (réactivité), outils de diagnostic : téléchargés seulement si Internet répond, sinon ignorés |

### Ce qui se passe pendant l'installation

1. Partitions : partition EFI de 2 Go montée sur `/boot`, puis la racine. En btrfs : sous-volumes `@`, `@home`, `@cache`, `@log`, `@snapshots`, compression zstd. Pas de partition d'échange (zram).
2. Copie du système live (`/run/archiso/airootfs`) : aucun téléchargement.
3. Module `orbe` (`calamares/orbe-module/main.py`) :
   - retire la configuration de la session live (compte `orbe`, sudo sans mot de passe, services de l'ISO, journal en mémoire) ;
   - remet le noyau dans `/boot` (archiso le retire de l'image) ;
   - greetd : écran de connexion Orbe, ouverture automatique si elle a été cochée ;
   - dépôt multilib actif (`/etc/pacman.conf` d'Orbe), nettoyage du cache de pacman chaque semaine (`paccache.timer`) ;
   - btrfs : configuration snapper `root` (instantanés avant et après chaque mise à jour grâce à snap-pac, 12 gardés au plus) et `grub-btrfsd` (instantanés au menu de démarrage) ;
   - clés de pacman, compte root verrouillé, installateur désinstallé.
4. initramfs (hooks calculés par Calamares, dont `plymouth` et `encrypt`), thème Plymouth `orbe`, services (NetworkManager, Bluetooth, greetd, détection du GPU...).
5. Avec Internet : mise à jour complète (`pacman -Syu`), options choisies (noyaux), puis carte NVIDIA : `orbe-nvidia` installe `lib32-nvidia-utils` et le module de chaque noyau. Sans Internet, le premier démarrage le propose (Réglages Orbe, Mode jeu). Dans tous les cas, le pilote NVIDIA est fixé : modules dans l'initramfs, nouveau exclu, services de veille NVIDIA actifs.
6. GRUB avec le thème Orbe (`orbe-grub-theme`), entrée EFI « orbe ».

### Chiffrement

Le disque est chiffré en LUKS2 ; le noyau reste sur la partition EFI (non chiffrée) et c'est l'initramfs qui ouvre le disque : GRUB n'a jamais à lire de LUKS2 (il ne sait pas le faire avec argon2, voir `docs/ETAT.md`). Le mot de passe est demandé sur l'écran de démarrage Orbe. Limite : en démarrage BIOS (sans UEFI), ce montage n'est pas possible ; le chiffrement demande l'UEFI.

## Après l'installation

- **Premier démarrage** : écran de connexion Orbe (`orbe-greeter`, Quickshell dans cage), puis l'assistant de bienvenue (fond d'écran, barre, météo, applications à installer, raccourcis).
- **Mises à jour** : Réglages Orbe, Mises à jour (`orbe-update` : instantané, puis `pacman -Syu`).
- **Revenir en arrière** (btrfs) : au démarrage, menu GRUB, « Orbe OS snapshots », choisir l'instantané d'avant la mise à jour. Pour le rendre permanent : `sudo snapper rollback` depuis l'instantané démarré, puis redémarrer.

## Dépôt `[orbe]` et mises à jour des paquets Orbe

Les paquets Orbe (`orbe-shell`, `orbe-desktop`, thèmes, Decky Loader, Calamares...) sont aujourd'hui dans l'ISO seulement : le système installé les reçoit à l'installation, mais pas leurs mises à jour. **Décision à prendre par Yass** : héberger le dépôt `[orbe]` (par exemple en fichiers de version GitHub d'un dépôt **public**, ou sur un petit serveur), le signer avec une clé GPG, puis l'ajouter à `/etc/pacman.conf` du système installé. Les paquets d'Arch, eux, se mettent à jour normalement.

## Installation en mode texte (archinstall)

`calamares/archinstall/orbe.json` décrit une installation équivalente pour `archinstall --config` (ext4 ou btrfs, français, greetd). Elle télécharge tout depuis les miroirs d'Arch et ne connaît pas le dépôt `[orbe]` : elle donne un Arch avec Hyprland, à compléter par les paquets Orbe une fois le dépôt hébergé. L'installateur graphique reste la voie recommandée.
