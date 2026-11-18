# Orbe Launcher sous Linux : rapport

Analyse demandée par le cahier des charges (section 4). Lecture seule du dépôt public `Yasder5/orbe-launcher` (commit `9a7fca6`) : **rien n'a été modifié**, le portage attend l'accord de Yass.

## En bref

Le portage est réaliste et ne touche presque pas à l'interface. Le rendu (React, thèmes, navigation à la manette par la Gamepad API, sons, clavier virtuel) fonctionne tel quel dans Electron sous Linux. Le travail porte sur le processus principal : là où le launcher lit le registre Windows, appelle des DLL ou lance des commandes Windows. Ordre de grandeur : quelques jours de travail, surtout pour les scanners de jeux et le retour au launcher pendant une partie.

## Ce qui marche déjà

- Toute l'interface : écrans, thèmes, i18n FR/EN, focus spatial, sons, vibration.
- Manettes Xbox et PlayStation dans l'interface : Chromium lit la Gamepad API sous Linux (evdev).
- `win/procs.ts` sait déjà lister les processus par `/proc` (prévu pour le développement).
- `scanners/reg.ts`, `win/xinput.ts` et `win/power.ts` renvoient déjà « rien » hors de Windows : pas de plantage, seulement des fonctions absentes.

## Ce qu'il faut écrire

| Module | Windows aujourd'hui | Linux |
|---|---|---|
| Scanner Steam | registre + `C:\Program Files (x86)\Steam` | `~/.local/share/Steam` (et Flatpak `~/.var/app/com.valvesoftware.Steam/...`), même `libraryfolders.vdf` et `appmanifest_*.acf` : le parseur VDF sert tel quel, seul `path.win32` est à remplacer. |
| Epic, GOG | manifestes et registre | via **Heroic Games Launcher** : `~/.config/heroic/legendaryConfig/legendary/installed.json` (Epic) et `gog_store/installed.json` (GOG), lancement par `heroic://launch/...`. |
| Ubisoft, EA | registre | pas d'équivalent direct : passent par Heroic, Lutris ou Steam (jeu non-Steam). À traiter plus tard. |
| Nouveau : jeux installés | | fichiers `.desktop` de catégorie `Game` (`/usr/share/applications`, `~/.local/share/applications`) : émulateurs, jeux natifs, Lutris. |
| Bouton Guide en jeu | XInput par `koffi` (`xinput1_4.dll`) | lecture directe de `/dev/input/event*` en Node (structures `input_event` de 24 octets, sans module natif). L'accès aux manettes est donné à la session par les règles udev de Steam (`uaccess`). |
| Fin de partie | chemin de l'exe du jeu | sous Proton, le processus est Wine : chercher plutôt `AppId=<id>` dans `/proc/<pid>/cmdline` (processus `reaper` de Steam). |
| Veille, redémarrage, arrêt | `shutdown`, `rundll32` | `systemctl suspend`, `systemctl reboot`, `systemctl poweroff` (autorisés par logind pour la session active). |
| Premier plan après la partie | `setAlwaysOnTop` | sans effet sous Wayland : sur le bureau, demander le focus à Hyprland ; en mode jeu, c'est gamescope qui gère le focus. |
| Lancement au démarrage | `setLoginItemSettings` | non pris en charge par Electron sous Linux : fichier `.desktop` dans `~/.config/autostart`, ou lancement par la session du mode jeu. |
| Journaux | `%APPDATA%\OrbeLauncher\logs` | `app.getPath('logs')` (`~/.config/Orbe Launcher/logs`). |
| Paquet | NSIS + portable | PKGBUILD `orbe-launcher` dans `[orbe]`, compilé avec l'Electron des dépôts Arch, ou AppImage via electron-builder. |

## Place dans Orbe OS

- **Bureau** : entrée « Mode jeu » qui ouvre le launcher en plein écran (demande du cahier des charges).
- **Mode jeu** (voir `docs/mode-jeu.md`) : le launcher peut devenir l'accueil de la session gamescope, avec Steam lancé en arrière-plan pour les jeux Steam. Electron y tourne en X11 (Xwayland), ce que gamescope attend.

## Proposition

1. Garder Steam Big Picture comme accueil du mode jeu au départ.
2. Porter le launcher par étapes, dans son propre dépôt : scanners Linux (Steam, Heroic, `.desktop`), puis bouton Guide par evdev, puis paquet `[orbe]`.
3. Le proposer ensuite comme accueil du mode jeu, au choix dans les réglages.
