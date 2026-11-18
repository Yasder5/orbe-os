#!/usr/bin/env python3
"""Module Calamares « orbe » : transforme la copie du système live en système installé.

Lancé après « users » (le compte existe) et avant « initcpiocfg » (l'initramfs est refait ensuite).
- retire ce qui ne sert qu'à la session live (compte orbe, sudo sans mot de passe, services) ;
- remet le noyau dans /boot (archiso le retire de l'image) ;
- greetd : greeter Orbe, ouverture automatique de la session si elle a été demandée ;
- Decky Loader pour le nouveau compte ;
- btrfs : configuration snapper « root » et entrées des instantanés dans GRUB ;
- clés de pacman, mot de passe root verrouillé.
"""
import glob
import os
import shutil

import libcalamares
from libcalamares.utils import debug, target_env_call, warning

# Fichiers de la session live, relatifs à la racine du système installé.
LIVE_FILES = [
    "etc/sudoers.d/orbe-live",
    "etc/sysusers.d/orbe-live.conf",
    "etc/tmpfiles.d/orbe-live.conf",
    "etc/mkinitcpio.conf.d/archiso.conf",
    "etc/motd",
    "etc/ssh/sshd_config.d/10-archiso.conf",
    "etc/systemd/journald.conf.d/volatile-storage.conf",
    "etc/systemd/logind.conf.d/do-not-suspend.conf",
    "etc/systemd/resolved.conf.d/archiso.conf",
    "etc/systemd/network/20-ethernet.network",
    "etc/systemd/network/20-wlan.network",
    "etc/systemd/network/20-wwan.network",
    "etc/systemd/system/choose-mirror.service",
    "etc/systemd/system/pacman-init.service",
    "etc/systemd/system/etc-pacman.d-gnupg.mount",
    "etc/systemd/system/livecd-talk.service",
    "etc/systemd/system/livecd-alsa-unmuter.service",
    "etc/systemd/system/sound.target.wants/livecd-alsa-unmuter.service",
    "etc/systemd/system/sockets.target.wants/pcscd.socket",
    "etc/systemd/system/multi-user.target.wants/choose-mirror.service",
    "etc/systemd/system/multi-user.target.wants/pacman-init.service",
    "etc/systemd/system/multi-user.target.wants/livecd-talk.service",
    "etc/systemd/system/multi-user.target.wants/sshd.service",
    "etc/systemd/system/multi-user.target.wants/hv_fcopy_daemon.service",
    "etc/systemd/system/multi-user.target.wants/hv_kvp_daemon.service",
    "etc/systemd/system/multi-user.target.wants/hv_vss_daemon.service",
    "etc/systemd/system/multi-user.target.wants/vboxservice.service",
    "etc/systemd/system/multi-user.target.wants/vmtoolsd.service",
    "etc/systemd/system/multi-user.target.wants/vmware-vmblock-fuse.service",
    "etc/systemd/system/multi-user.target.wants/decky-loader@orbe.service",
    "root/.automated_script.sh",
    "root/.zlogin",
    "usr/local/bin/Installation_guide",
    "usr/local/bin/choose-mirror",
    "usr/local/bin/livecd-sound",
    "usr/local/share/livecd-sound",
    "etc/systemd/system/cloud-init.target.wants",
]

GREETD = """# greetd (Orbe OS) : greeter Orbe, puis orbe-session (bureau ou mode jeu, la dernière utilisée).
[terminal]
vt = 1

[default_session]
command = "orbe-greeter"
user = "greeter"
"""

SNAPPER = """# Instantanés de « / » (Orbe OS). Créés avant et après chaque mise à jour (snap-pac),
# visibles au démarrage dans GRUB (grub-btrfs). Pas d'instantanés horaires.
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS="wheel"
SYNC_ACL="yes"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="12"
NUMBER_LIMIT_IMPORTANT="6"
TIMELINE_CREATE="no"
TIMELINE_CLEANUP="yes"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
"""


def pretty_name():
    return "Réglages d'Orbe OS"


def remove(root, rel):
    path = os.path.join(root, rel)
    if os.path.islink(path) or os.path.isfile(path):
        os.unlink(path)
    elif os.path.isdir(path):
        shutil.rmtree(path)


def write(root, rel, text, mode=0o644):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    os.chmod(path, mode)


def root_is_btrfs():
    for part in libcalamares.globalstorage.value("partitions") or []:
        if part.get("mountPoint") == "/":
            return part.get("fs") == "btrfs"
    return False


def run():
    root = libcalamares.globalstorage.value("rootMountPoint")
    user = libcalamares.globalstorage.value("username")
    autologin = libcalamares.globalstorage.value("autoLoginUser")
    if not root or not user:
        return ("Réglages d'Orbe OS", "Point de montage ou compte inconnu.")

    for rel in LIVE_FILES:
        remove(root, rel)

    # Noyau : archiso le retire de /boot dans l'image, il reste dans /usr/lib/modules.
    kernels = sorted(glob.glob(os.path.join(root, "usr/lib/modules/*/vmlinuz")))
    for vmlinuz in kernels:
        pkgbase = os.path.join(os.path.dirname(vmlinuz), "pkgbase")
        name = open(pkgbase).read().strip() if os.path.exists(pkgbase) else "linux"
        # copyfile : la partition EFI (vfat) refuse les droits et dates de copy2.
        shutil.copyfile(vmlinuz, os.path.join(root, "boot", "vmlinuz-" + name))
        debug("Noyau copié : vmlinuz-" + name)

    # greetd : greeter Orbe ; ouverture automatique si l'utilisateur l'a demandée.
    config = GREETD
    if autologin:
        config += '\n[initial_session]\ncommand = "orbe-session"\nuser = "{}"\n'.format(autologin)
    write(root, "etc/greetd/config.toml", config)

    # Decky Loader (thème Steam) pour le nouveau compte.
    wants = os.path.join(root, "etc/systemd/system/multi-user.target.wants")
    os.makedirs(wants, exist_ok=True)
    unit = "/usr/lib/systemd/system/decky-loader@.service"
    if os.path.exists(os.path.join(root, unit.lstrip("/"))):
        link = os.path.join(wants, "decky-loader@{}.service".format(user))
        if not os.path.lexists(link):
            os.symlink(unit, link)

    # Instantanés btrfs : snapper sur « / » (sous-volume @snapshots monté sur /.snapshots).
    if root_is_btrfs():
        write(root, "etc/snapper/configs/root", SNAPPER, 0o640)
        write(root, "etc/conf.d/snapper", 'SNAPPER_CONFIGS="root"\n')
        snapshots = os.path.join(root, ".snapshots")
        os.makedirs(snapshots, exist_ok=True)
        os.chmod(snapshots, 0o750)
        target_env_call(["systemctl", "enable", "grub-btrfsd.service"])

    # pacman : clés du système installé (celles du live étaient en mémoire).
    target_env_call(["pacman-key", "--init"])
    target_env_call(["pacman-key", "--populate", "archlinux"])

    # L'installateur ne sert plus une fois le système installé.
    target_env_call(["pacman", "-Rns", "--noconfirm", "orbe-installer", "calamares"])

    # root sans mot de passe dans l'image live : compte verrouillé (sudo pour l'administration).
    target_env_call(["passwd", "-l", "root"])
    return None
