# Orbe OS

Distribution Linux basée sur Arch, pensée pour le jeu et le quotidien : bureau Wayland (Hyprland + Quickshell) aux couleurs de l'univers Orbe, installable depuis une ISO live.

Projet en construction : l'avancement réel est dans [`JOURNAL.md`](JOURNAL.md).

## Construire l'ISO

Il faut Docker (le conteneur doit pouvoir tourner en `--privileged`) et environ 30 Go libres. Depuis Windows, tout se fait dans WSL2 : voir [`docs/demarrage-wsl.md`](docs/demarrage-wsl.md).

```bash
./build.sh
```

L'ISO arrive dans `out/iso/orbe-os-AAAA.MM.JJ-x86_64.iso`, avec sa somme SHA-256. `./build.sh --fast` compresse moins, pour les essais. `bash tools/preflight.sh` vérifie la machine.

## Tester dans une machine virtuelle

```bash
./test.sh
```

UEFI par défaut, `--bios` pour l'autre mode, `--disk orbe.qcow2` pour installer sur un disque virtuel, `--gl` pour l'accélération 3D. `./test.sh --help` liste les options.

## Organisation

| Dossier | Contenu |
|---|---|
| `archiso/` | profil de l'ISO (paquets, fichiers du live, menus de démarrage) |
| `packages/` | un PKGBUILD par paquet Orbe, publiés dans le dépôt `[orbe]` |
| `shell/` | Orbe Shell en QML (Quickshell) |
| `themes/` | GTK, Qt, icônes, curseur, Plymouth, GRUB, terminal |
| `calamares/` | configuration et habillage de l'installateur |
| `wallpapers/` | fonds d'écran |
| `docs/` | cahier des charges, raccourcis, architecture |
| `tools/` | scripts de construction et de vérification |
| `LICENSES/` | licences des ressources embarquées |

## Licences

Licence du code Orbe : à choisir. Les polices et autres ressources tierces gardent leur licence, listée dans `LICENSES/`. Orbe Shell est une réécriture inspirée de [Caelestia Shell](https://github.com/caelestia-dots/shell) (GPL-3.0), sans reprise de son code.
