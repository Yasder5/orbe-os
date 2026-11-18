# Tester Orbe OS sur un vrai PC

Guide de l'étape 9. Tout ce qui suit n'a été vérifié qu'en machine virtuelle (QEMU sans accélération graphique) : le premier démarrage sur ton PC est le vrai test. Rien n'est écrit sur le disque tant que tu ne lances pas l'installateur.

## 1. Préparer la clé USB (8 Go ou plus)

**Avec Ventoy (recommandé, garde la clé utilisable pour d'autres ISO)** : installe Ventoy sur la clé (ventoy.net, une fois), puis copie simplement `orbe-os-AAAA.MM.JJ-x86_64.iso` dessus. Le menu Orbe s'affiche après celui de Ventoy (`loopback.cfg`).

**Avec `dd` (efface toute la clé)**, depuis Linux ou WSL ; vérifie d'abord le nom de la clé avec `lsblk`, une erreur de lettre efface le mauvais disque :

```bash
sudo dd if=out/iso/orbe-os-AAAA.MM.JJ-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Sous Windows sans WSL : Rufus en mode « image DD ».

## 2. Réglages du PC (BIOS / UEFI)

- **Secure Boot désactivé** : l'ISO n'a pas de chargeur signé (pas de shim).
- Démarrage en **UEFI** (le mode BIOS fonctionne aussi, mais l'installation chiffrée demande l'UEFI).
- Touche du menu de démarrage : souvent F8 (ASUS), F11 (MSI), F12 (Gigabyte).

## 3. Points à vérifier dans la session live

Coche au fur et à mesure, et note ce qui ne va pas (une photo de l'écran suffit).

**Démarrage**
- [ ] Menu GRUB Orbe (UEFI) ou syslinux (BIOS), lisible, souris et clavier OK.
- [ ] Écran Plymouth : l'orbe se forme, sans texte de démarrage par-dessus.
- [ ] Bureau en moins d'une minute environ, clavier AZERTY.

**Carte graphique NVIDIA RTX 3050 (cas prioritaire)**
- [ ] Entrée « Démarrer Orbe OS » : le pilote NVIDIA (`nvidia-open`) est choisi tout seul. Vérifier dans un terminal : `nvidia-smi` répond, et `lspci -k | grep -A3 -E "VGA|3D"` indique « Kernel driver in use: nvidia ».
- [ ] Animations fluides (orbe animé : Super + W, « Orbe vivant »).
- [ ] Si écran noir : redémarrer sur « Démarrer Orbe OS avec pilotes libres » et me le signaler.

**Double écran**
- [ ] Les deux écrans s'allument, avec leur définition et leur fréquence maximales (144 Hz, etc.).
- [ ] Chaque écran a sa barre et ses propres espaces de travail (Super + 1 à 9).
- [ ] Réglages Orbe, Écrans : changer la position ou l'échelle s'applique tout de suite.

**Réseau et son**
- [ ] Wi-Fi : Super + A, choisir le réseau, mot de passe, connexion.
- [ ] Son : touches de volume (jauge à l'écran), sortie HDMI ou casque dans Réglages Orbe, Son.
- [ ] Bluetooth : manette ou casque appairé depuis Réglages Orbe, Bluetooth.

**Mode jeu**
- [ ] Super + G : les fenêtres se ferment, Steam s'ouvre en plein écran (Big Picture). Premier lancement : Steam se télécharge (300 Mo et plus).
- [ ] Thème Orbe dans Steam (noir, citron, police Archivo). Sinon : bouton « ... » de la manette, menu Decky, CSS Loader, activer « Orbe ».
- [ ] Un jeu Proton se lance, le compteur MangoHud (menu rapide de Steam, Performances) s'affiche.
- [ ] Menu d'alimentation de Steam, « Revenir au bureau » : retour au bureau Orbe.

**Veille**
- [ ] Menu de session (Super + Échap), « Mettre en veille », puis réveil au clavier ou à la souris : l'écran revient, le Wi-Fi se reconnecte.
- [ ] Avec NVIDIA : pas d'écran noir ni de fenêtres corrompues au réveil.

## 4. Installation

Lance « Installer Orbe OS » (proposé par l'assistant de bienvenue, ou dans le lanceur). Choix conseillés : effacer le disque, **btrfs** (instantanés avant chaque mise à jour), chiffrement si c'est un portable. L'installation copie la session live : pas besoin d'Internet, sauf pour les pilotes NVIDIA 32 bits (jeux Proton anciens), installés seulement si le réseau répond.

Après le redémarrage :
- [ ] Écran de connexion Orbe, puis assistant de bienvenue.
- [ ] Le mot de passe du disque chiffré est demandé sur l'écran de démarrage Orbe.
- [ ] Réglages Orbe, Mises à jour : « Tout mettre à jour » fonctionne (un instantané est pris avant).
- [ ] Menu GRUB : les instantanés apparaissent dans « Instantanés » après une mise à jour.

## 5. Me remonter un problème

Dans un terminal (Super + Entrée) :

```bash
journalctl -b -p 3 --no-pager > ~/erreurs.txt
```

```bash
cat ~/.local/state/orbe/jeu.log
```

Le premier liste les erreurs du démarrage, le second le journal du dernier mode jeu. Ne partage pas de mot de passe ni de clé dans ces fichiers.
