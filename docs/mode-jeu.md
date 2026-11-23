# Mode jeu

Demande de Yass (2026-11-17) : un système pensé d'abord pour lancer les jeux, à la manière de SteamOS, avec une interface soignée.

## Deux sessions, une seule commande

| | Bureau Orbe | Mode jeu Orbe |
|---|---|---|
| Compositeur | Hyprland | gamescope (le compositeur de Valve, celui de SteamOS) |
| Interface | Orbe Shell | Steam en mode Big Picture, thème Orbe |
| Usage | travail, navigation, réglages | jeux, à la télé ou au bureau, à la manette |

- greetd lance `orbe-session`, qui ouvre la **dernière session utilisée** (`~/.local/state/orbe/session` : `bureau` ou `jeu`).
- Du bureau au mode jeu : bouton manette de la barre, entrée « Mode jeu » du menu de session (Super + Échap) et du lanceur (taper « jeu »), ou **Super + G**. `orbe-switch-session jeu` ferme proprement les applications (hyprshutdown, qui laisse enregistrer), quitte Hyprland, puis `orbe-session` lance le mode jeu.
- Du mode jeu au bureau : « Revenir au bureau » dans le menu d'alimentation de Steam. Steam, lancé avec `-steamos3`, appelle `steamos-session-select`, fourni par Orbe OS.
- Si Steam ou gamescope se ferme sans demande, on revient au bureau sans changer la session enregistrée : impossible de rester bloqué sur un écran noir. Le bureau l'annonce (« Le mode jeu n'a pas démarré », bouton « Voir le journal »).
- **Mode de secours** : après deux échecs en moins de 10 minutes, ou si on le choisit dans Réglages Orbe, le mode jeu lance Steam Big Picture en plein écran dans un Hyprland dédié (`/usr/share/orbe/hypr/jeu-secours.lua`), sans gamescope. Utile si gamescope ne fonctionne pas avec une carte graphique.
- Le réglage « Au démarrage » (dernière session, bureau, mode jeu) ne compte qu'à l'ouverture : les bascules demandées ensuite sont toujours suivies.

## Réglages Orbe, page Mode jeu

Écrits dans `~/.config/orbe/jeu.conf`, lus par `orbe-game-session` :
- écran utilisé par gamescope (`--prefer-output`), quand il y en a plusieurs ;
- profil d'énergie « performances » pendant le mode jeu (`powerprofilesctl launch`), rendu à la sortie ;
- moteur : gamescope ou secours ;
- Steam en arrière-plan sur le bureau (`steam -silent`) : la manette sert de souris et de clavier, le bouton Guide ouvre Big Picture ;
- pilote NVIDIA 32 bits (`orbe-nvidia`), proposé s'il manque.

## Ce que lance le mode jeu

`orbe-game-session` : `gamescope --steam --mangoapp --xwayland-count 2 --adaptive-sync -- steam -gamepadui -steamos3 -steampal`, avec les variables d'environnement d'une session SteamOS (VRR, déchirement autorisé, mise à l'échelle NIS, volume, clavier visuel de Steam, MangoHud piloté par le curseur « Performances » de Steam). Journal de la dernière partie : `~/.local/state/orbe/jeu.log`.

## Thème Steam Orbe

Le skin d'Orbe Launcher (`themes/steam/Orbe`, MIT) est appliqué par **CSS Loader**, un greffon de **Decky Loader**. Les deux sont empaquetés dans `[orbe]` depuis leurs binaires officiels (`decky-loader-bin` 3.3.1, GPL-2.0 ; `decky-plugin-css-loader` 2.1.2, GPL-3.0). Le service `decky-loader@<compte>` tourne en root (comme sur le Steam Deck) avec ses greffons dans `~/homebrew`. Sur le système installé, il est démarré par le mode jeu pour le compte qui l'ouvre (règle polkit, sans mot de passe), et les instances des autres comptes sont arrêtées : elles écoutent le même port. Au lancement du mode jeu, `orbe-steam-setup` copie CSS Loader et le thème Orbe dans `~/homebrew`, active le thème (police Archivo et fond orbe) et autorise le débogage distant de Steam, dont Decky a besoin. Les choix faits ensuite dans CSS Loader sont gardés.

## Optimisations pour le jeu (paquet `orbe-gaming`)

- **Proton et Vulkan 32 bits** : `lib32-mesa`, `lib32-vulkan-radeon`, `lib32-vulkan-intel` dans l'ISO, dépôt multilib actif sur le système installé. `lib32-nvidia-utils` (580 Mo installé) est installé par `orbe-nvidia` : par l'installateur si Internet répond, sinon proposé au premier démarrage.
- **NVIDIA sur le système installé** : pilote fixé à l'installation (modules dans l'initramfs, nouveau exclu, services de veille NVIDIA). Noyau LTS : `nvidia-open-lts` ; noyau Zen ou autre : `nvidia-open-dkms` et les en-têtes. Si la carte tourne malgré tout sur nouveau, le bureau le signale.
- **ntsync** : module chargé au démarrage, `/dev/ntsync` accessible (Proton et Wine récents).
- **zram** : échange compressé en mémoire, la moitié de la RAM au plus (8 Go), réglages d'échange du wiki Arch.
- **`vm.max_map_count`** à la valeur de SteamOS, **`split_lock_mitigate`** désactivé.
- **GameMode** (compte dans le groupe `gamemode`) : option de lancement Steam `gamemoderun %command%`.
- **MangoHud** aux couleurs d'Orbe sur le bureau (`mangohud %command%`, Maj droite + F12) ; en mode jeu, c'est Steam qui le règle.
- **VRR** et déchirement autorisé : Hyprland (`vrr = 2`, règle `immediate` pour les jeux Steam) et gamescope.
- **Manettes** : règles udev de Steam (`steam-devices`) et de `game-devices-udev` (8BitDo, Nintendo, PlayStation, Stadia...), DualSense, DualShock et Switch Pro gérés par le noyau, `xpadneo` pour les manettes Xbox en Bluetooth (DKMS, avec les en-têtes du noyau). Les manettes appairées sont marquées « de confiance » : elles se reconnectent seules.
- **Enregistrement** : `gpu-screen-recorder` (NVENC, VA-API), raccourcis Super + Maj + R et Super + Maj + G, indicateur fixe dans la barre.
- **`scx_lavd`** (sched-ext, 150 Mo avec les autres ordonnanceurs) : en option (`scx-scheds`), pas dans l'ISO.

## Limites connues

- Testé en machine virtuelle seulement pour la bascule entre les sessions. gamescope demande une carte graphique Vulkan avec un nœud DRM, absente de la VM, et Steam télécharge plus de 300 Mo au premier lancement : **le mode jeu lui-même et le thème Steam sont à valider sur le PC de Yass** (guide de l'étape 9).
- Steam reste maître de son interface : une mise à jour de Steam peut casser des sélecteurs du thème (voir `themes/steam/README` d'Orbe Launcher et son `tools/check.py`).
- Decky Loader peut se mettre à jour lui-même depuis Steam ; la version du paquet reprend la main à la mise à jour suivante d'Orbe OS.
- `xpadneo` : recette prête, mais sa source GitHub est injoignable depuis la session de construction : il sera dans l'ISO construite sur le PC de Yass. `xone` (dongle Xbox sans fil) n'est pas empaqueté : son micrologiciel est sous licence Microsoft.

## Choix validés par Yass (2026-11-18)

1. Accueil du mode jeu : **Steam Big Picture d'abord, Orbe Launcher ensuite**, quand son portage Linux sera prêt.
2. Démarrage du système installé : **dernière session utilisée** (bureau ou mode jeu), modifiable dans les réglages.
