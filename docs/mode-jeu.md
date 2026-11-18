# Mode jeu : proposition

Demande de Yass (2026-11-17) : un système pensé d'abord pour lancer les jeux, à la manière de SteamOS, avec une interface soignée. Ce document décrit ce qui est prévu et liste les choix à valider. Rien de ce qui suit n'est encore construit.

## Deux sessions, un seul système

| | Bureau Orbe | Mode jeu Orbe |
|---|---|---|
| Compositeur | Hyprland | gamescope (le compositeur de Valve, celui de SteamOS) |
| Interface | Orbe Shell (barre, lanceur, réglages) | plein écran, pensée pour la manette |
| Usage | travail, navigation, réglages | jeux, à la télé ou au bureau |

- On passe de l'un à l'autre en une action : bouton « Mode jeu » dans la barre et le lanceur (Super + G), entrée « Revenir au bureau » dans le mode jeu.
- Au démarrage, greetd ouvre la dernière session utilisée. Une option permet de démarrer directement en mode jeu, comme une console.

## Accueil du mode jeu

Trois possibilités, à choisir :

1. **Steam en mode Big Picture** (`steam -gamepadui` dans gamescope). C'est ce que fait SteamOS : compatibilité maximale, mises à jour assurées par Valve, mais l'interface est celle de Steam, pas celle d'Orbe.
2. **Orbe Launcher** comme accueil, qui réunit Steam, Epic et GOG (via Heroic), les émulateurs, etc. L'identité Orbe est complète, mais le launcher est pensé pour Windows : il faut d'abord un portage Linux (rapport à venir, aucune modification sans accord).
3. **Les deux** : Steam Big Picture par défaut tout de suite, Orbe Launcher en option dès que le portage Linux est prêt. **Recommandé.**

## Optimisations pour le jeu

Prévues dans le système installé, mesurées avant d'être gardées :

- **Proton et Vulkan 32 bits** : pilotes `lib32` (Mesa, NVIDIA), dépôt multilib déjà actif.
- **ntsync** : module du noyau chargé au démarrage, utilisé par Proton récent pour la synchronisation Windows (gain net sur certains jeux).
- **Ordonnanceur `scx_lavd`** (sched-ext) : conçu pour réduire la latence en jeu, financé par Valve pour le Steam Deck. Optionnel, activé en mode jeu.
- **GameMode** : performances maximales du processeur pendant une partie.
- **MangoHud** : compteur d'images et températures, affiché ou masqué par raccourci.
- **zram** à la place d'une partition d'échange, `split_lock_mitigate` désactivé comme sur SteamOS.
- **VRR** (FreeSync, G-Sync compatible) et tearing autorisé pour les jeux qui le demandent : déjà dans la configuration Hyprland.
- **Manettes** : règles udev de Steam, DualSense et DualShock pris en charge par le noyau, manettes Xbox en Bluetooth via `xpadneo`.
- **Noyau** : `linux` par défaut, `linux-zen` proposé dans l'installateur (orienté réactivité), `linux-lts` en secours.

## Interface et expérience

- Navigation complète à la manette dans tout le mode jeu, anneau de focus Orbe, sons de navigation d'Orbe Launcher (déplacer, valider, retour, lancer).
- Bouton Guide : retour à l'accueil depuis n'importe quel jeu, avec un menu rapide (volume, luminosité, profil d'énergie, quitter le jeu).
- Assistant de bienvenue : propose d'installer Steam, Heroic, Discord, OBS et les outils de jeu, et de choisir le démarrage en mode jeu.

## Choix validés par Yass (2026-11-18)

1. Accueil du mode jeu : **Steam Big Picture d'abord, Orbe Launcher ensuite** (possibilité 3), quand son portage Linux sera prêt.
2. Démarrage du système installé : **dernière session utilisée** (bureau ou mode jeu), modifiable dans les réglages.

Paquets à reconstruire depuis l'AUR dans `[orbe]` : `gamescope-session-steam` (sessions façon SteamOS), `xpadneo-dkms`, `game-devices-udev`. Les autres sont dans les dépôts officiels.
