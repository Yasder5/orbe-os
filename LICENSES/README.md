# Licences

Le code d'Orbe OS (scripts, QML, configurations, générateurs) est sous licence **MIT** (`LICENSE` à la racine). Les images générées par ces scripts (orbe, fonds, curseur, écran de démarrage, menus GRUB et syslinux, logo) sont des œuvres du projet, sous la même licence.

## Ressources embarquées dans le dépôt

| Ressource | Où | Licence | Fichier |
|---|---|---|---|
| Police Archivo (Omnibus-Type) | `themes/fonts/`, `themes/steam/Orbe/fonts/` | SIL OFL 1.1 | `OFL-Archivo.txt` |
| Thème Steam et sons d'Orbe Launcher (Yass) | `themes/steam/Orbe/`, `themes/sounds/` | MIT | `MIT-orbe-launcher.txt` |

## Paquets tiers reconstruits dans `[orbe]`

| Paquet | Origine | Licence |
|---|---|---|
| `calamares` | recette AUR, sources Codeberg | GPL-3.0 ou plus récente |
| `heroic-games-launcher-bin` | recette AUR, binaire officiel | GPL-3.0 |
| `decky-loader-bin` | binaire officiel SteamDeckHomebrew | GPL-2.0 |
| `decky-plugin-css-loader` | archive officielle DeckThemes | GPL-3.0 |
| `orbe-icon-theme` | dossiers de Papirus recolorés (générés au build) | GPL-3.0, comme Papirus |

## Logiciels des dépôts d'Arch présents dans l'ISO (principaux)

Hyprland, hyprshutdown, hyprtoolkit (BSD-3-Clause), Quickshell (LGPL-3.0), Qt 6 (LGPL-3.0), GRUB, Plymouth, archiso (GPL), foot (MIT), fish (GPL-2.0), Papirus (GPL-3.0), JetBrains Mono (OFL), gamescope (BSD-2-Clause), MangoHud (MIT), GameMode (BSD-3-Clause).

Logiciels non libres, redistribuables d'après leurs licences et les paquets d'Arch : **Steam** (lanceur de Valve, dépôt multilib ; le client se télécharge au premier lancement) et les bibliothèques **nvidia-utils** (les modules `nvidia-open` du noyau sont sous MIT/GPL-2.0). À garder en tête avant de distribuer l'ISO publiquement.

## Lu sans être copié

Orbe Shell est une réécriture inspirée de l'ergonomie de [Caelestia Shell](https://github.com/caelestia-dots/shell) (GPL-3.0) : aucun fichier ni extrait de code n'en vient.
