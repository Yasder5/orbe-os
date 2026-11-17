#!/usr/bin/env bash
# shellcheck disable=SC2034
# Profil archiso d'Orbe OS, dérivé de releng (archiso 92).

iso_name="orbe-os"
iso_label="ORBE_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Orbe OS <https://github.com/Yasder5>"
iso_application="Orbe OS Live"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="orbe"
# GRUB en UEFI (x64 et IA32 mixte), syslinux en BIOS.
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
# zstd : décompression plus rapide que xz, donc session live plus réactive.
# ORBE_FAST=1 (build.sh --fast) : compression légère pour les essais.
if [[ "${ORBE_FAST:-0}" == 1 ]]; then
  airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3' '-b' '1M')
else
  airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
fi
kernel_params_x86_64=""
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
