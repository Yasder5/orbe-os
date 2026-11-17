#!/usr/bin/env bash
# Lancé par build.sh dans le conteneur Arch privilégié. Le dépôt est monté sur /orbe.
set -euo pipefail

log() { printf '\n==> %s\n' "$*"; }
repo=/orbe/out/repo/x86_64
isodir=/orbe/out/iso

finish() {
  # Les fichiers produits appartiennent à l'utilisateur de l'hôte, pas à root.
  [[ -d /orbe/out ]] && chown -R "${HOST_UID:-0}:${HOST_GID:-0}" /orbe/out || true
}
trap finish EXIT

log "Préparation de pacman"
if [[ -f /run/orbe-extra-ca.crt ]]; then
  cp /run/orbe-extra-ca.crt /etc/ca-certificates/trust-source/anchors/orbe-extra-ca.crt
  update-ca-trust
fi
# Le profil ISO utilise ce même mirrorlist (Include) : un seul miroir à régler.
echo "Server = ${ORBE_MIRROR:-https://geo.mirror.pkgbuild.com/\$repo/os/\$arch}" > /etc/pacman.d/mirrorlist
grep -q '^\[multilib\]' /etc/pacman.conf || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
pacman-key --init >/dev/null 2>&1
pacman-key --populate archlinux >/dev/null 2>&1
pacman -Syu --noconfirm --needed archiso grub base-devel git sudo

log "Dépôt [orbe]"
mkdir -p "$repo"
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
expected=()
for pkgbuild in /orbe/packages/*/PKGBUILD; do
  [[ -f "$pkgbuild" ]] || continue
  name=$(basename "$(dirname "$pkgbuild")")
  src=/build/$name
  rm -rf "$src" && mkdir -p /build && cp -a "$(dirname "$pkgbuild")" "$src" && chown -R builder: "$src" /build
  mapfile -t files < <(cd "$src" && sudo -u builder PKGDEST="$repo" makepkg --packagelist)
  expected+=("${files[@]}")
  missing=0
  for f in "${files[@]}"; do [[ -f "$f" ]] || missing=1; done
  if (( missing )); then
    log "Construction de $name"
    chown builder: "$repo"
    (cd "$src" && sudo -u builder PKGDEST="$repo" makepkg --syncdeps --cleanbuild --noconfirm --force)
  else
    echo "$name : déjà construit, ignoré"
  fi
done
# Supprime les anciennes versions, puis reconstruit la base du dépôt de zéro.
for f in "$repo"/*.pkg.tar.*; do
  [[ -f "$f" ]] || continue
  [[ " ${expected[*]} " == *" $f "* ]] || { echo "Suppression de $(basename "$f")"; rm -f "$f"; }
done
rm -f "$repo"/orbe.{db,files}*
if (( ${#expected[@]} )); then
  repo-add -q "$repo/orbe.db.tar.gz" "${expected[@]}"
else
  # Dépôt vide mais valide : pacman accepte une base sans entrée.
  bsdtar -czf "$repo/orbe.db.tar.gz" --files-from /dev/null
  cp "$repo/orbe.db.tar.gz" "$repo/orbe.files.tar.gz"
  ln -sf orbe.db.tar.gz "$repo/orbe.db"
  ln -sf orbe.files.tar.gz "$repo/orbe.files"
fi
echo "[orbe] : ${#expected[@]} paquet(s)"

[[ "${ORBE_PACKAGES_ONLY:-0}" == 1 ]] && exit 0

log "ISO"
# Copie de travail du profil : syslinux n'affiche que le CP437, on y convertit ses menus.
profile=/work/profile
rm -rf "$profile" /work/iso
cp -a /orbe/archiso "$profile"
for cfg in "$profile"/syslinux/*.cfg; do
  iconv -f UTF-8 -t CP437 "$cfg" -o "$cfg.cp437" && mv "$cfg.cp437" "$cfg"
done
mkdir -p "$isodir"
rm -f "$isodir"/orbe-os-*.iso "$isodir"/orbe-os-*.iso.sha256
mkarchiso -v -r -w /work/iso -o "$isodir" "$profile"
cd "$isodir"
for iso in orbe-os-*.iso; do sha256sum "$iso" > "$iso.sha256"; done
ls -lh "$isodir"
