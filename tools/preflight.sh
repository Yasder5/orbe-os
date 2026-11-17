#!/usr/bin/env bash
# Vérifie que la machine peut construire et tester Orbe OS. Lecture seule, sauf l'image Docker téléchargée.
fails=0
ok() { echo "OK     $1"; }
ko() { echo "ECHEC  $1"; fails=$((fails + 1)); }
info() { echo "INFO   $1"; }

info "Système : $(. /etc/os-release; echo "$PRETTY_NAME"), noyau $(uname -r)"
info "CPU : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
info "RAM : $(awk '/MemTotal/{printf "%.0f Go", $2/1048576}' /proc/meminfo)"
if command -v lspci >/dev/null; then info "GPU : $(lspci | grep -E 'VGA|3D' | cut -d: -f3 | xargs)"; else info "GPU : lspci absent"; fi

free_gb=$(df -BG --output=avail "$HOME" | tail -1 | tr -dc 0-9)
[ "$free_gb" -ge 50 ] && ok "Espace libre : ${free_gb} Go" || ko "Espace libre : ${free_gb} Go, 50 Go conseillés"

if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then ok "/dev/kvm accessible"
elif [ -e /dev/kvm ]; then ko "/dev/kvm présent sans accès : sudo usermod -aG kvm \$USER, puis reconnexion"
else ko "/dev/kvm absent : activer SVM ou VT-x dans le BIOS ; sous WSL2, vérifier la virtualisation imbriquée (Windows 11 requis sur AMD)"; fi

command -v git >/dev/null && ok "git présent" || ko "git absent : sudo apt install -y git"
command -v qemu-system-x86_64 >/dev/null && ok "QEMU présent" || ko "QEMU absent : sudo apt install -y qemu-system-x86 qemu-utils"

ovmf=$(ls /usr/share/edk2/x64/OVMF_CODE*.fd /usr/share/edk2-ovmf/x64/OVMF_CODE*.fd /usr/share/OVMF/OVMF_CODE*.fd 2>/dev/null | head -1)
[ -n "$ovmf" ] && ok "OVMF : $ovmf" || ko "OVMF absent, pas de test UEFI : sudo apt install -y ovmf"

case "$PWD" in /mnt/*) ko "Dossier sous /mnt : déplacer le projet dans ~/orbe-os" ;; esac
if grep -qi microsoft /proc/version; then
  info "WSL2 détecté"
  [ -n "$WAYLAND_DISPLAY$DISPLAY" ] && ok "WSLg actif" || ko "WSLg inactif, pas de fenêtre QEMU : wsl --update côté Windows"
fi

[ "$(git config --global user.name)" = yasder5 ] && ok "git user.name = yasder5" || ko "git user.name : git config --global user.name yasder5"
[ "$(git config --global user.email)" = yasser@boulayoune.com ] && ok "git user.email correct" || ko "git user.email : git config --global user.email yasser@boulayoune.com"

if ! command -v docker >/dev/null; then ko "Docker absent : sudo apt install -y docker.io && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER, puis reconnexion"
elif ! docker info >/dev/null 2>&1; then ko "Docker inaccessible : sudo systemctl enable --now docker && sudo usermod -aG docker \$USER, puis reconnexion"
else
  ok "Docker accessible"
  echo "Versions actuelles dans archlinux:latest :"
  docker run --rm archlinux:latest bash -c 'pacman -Sy >/dev/null 2>&1; for p in quickshell hyprland archiso greetd grub-btrfs qt6-base calamares ttf-archivo; do pacman -Si "$p" 2>/dev/null | awk -v p="$p" -F": " "/^Version/{print \"  \" p \" \" \$2; f=1} END{if(!f) print \"  \" p \" absent\"}"; done' || ko "Conteneur Arch impossible à lancer"
  docker run --rm --privileged archlinux:latest true >/dev/null 2>&1 && ok "Conteneur privilégié autorisé" || ko "Conteneur privilégié refusé, mkarchiso ne pourra pas tourner"
fi

echo
[ "$fails" -eq 0 ] && echo "Machine prête." || echo "$fails point(s) à corriger."
exit "$fails"
