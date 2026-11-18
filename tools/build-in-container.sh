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
# freetype2, python-fonttools et ttf-jetbrains-mono : polices du thème GRUB.
# qt6-shadertools : compilation des shaders d'Orbe Shell.
pacman -Syu --noconfirm --needed archiso grub freetype2 python-fonttools ttf-jetbrains-mono qt6-shadertools base-devel git sudo

log "Shaders d'Orbe Shell"
bash /orbe/tools/build-shaders.sh /orbe/shell/shaders

log "Dépôt [orbe]"
mkdir -p "$repo"
id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
# Les PKGBUILD Orbe lisent leurs sources dans le dépôt (ORBE_SRC) et leur version dans ORBE_VERSION.
mkpkg() { sudo -u builder env ORBE_SRC=/orbe ORBE_VERSION="${ORBE_VERSION:-0.1.0}" PKGDEST="$repo" makepkg "$@"; }
expected=()
skipped=()
for pkgbuild in /orbe/packages/*/PKGBUILD; do
  [[ -f "$pkgbuild" ]] || continue
  name=$(basename "$(dirname "$pkgbuild")")
  src=/build/$name
  rm -rf "$src" && mkdir -p /build && cp -a "$(dirname "$pkgbuild")" "$src" && chown -R builder: "$src" /build "$repo"
  mapfile -t files < <(cd "$src" && mkpkg --packagelist)
  expected+=("${files[@]}")
  missing=0
  for f in "${files[@]}"; do [[ -f "$f" ]] || missing=1; done
  if [[ "$name" == orbe-* ]]; then
    # Paquets Orbe : de simples fichiers, reconstruits à chaque fois, sans dépendance de construction.
    log "Construction de $name"
    (cd "$src" && mkpkg --nodeps --cleanbuild --noconfirm --force)
  elif (( missing )); then
    # Paquets reconstruits depuis l'AUR : seulement quand leur version change. Un échec (source
    # injoignable, par exemple) n'arrête pas le build : le paquet manquera, l'ISO s'en passera.
    log "Construction de $name"
    if ! (cd "$src" && mkpkg --syncdeps --cleanbuild --noconfirm --force); then
      echo "ATTENTION : $name n'a pas pu être construit, il sera absent de l'ISO." >&2
      skipped+=("$name")
    fi
  else
    echo "$name : déjà construit, ignoré"
  fi
done
# Garde seulement les paquets réellement produits (--packagelist annonce aussi les paquets -debug).
built=()
for f in "${expected[@]}"; do [[ -f "$f" ]] && built+=("$f"); done
expected=("${built[@]}")
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
echo "[orbe] : ${#expected[@]} paquet(s)${skipped[*]:+, absents : ${skipped[*]}}"

[[ "${ORBE_PACKAGES_ONLY:-0}" == 1 ]] && exit 0

log "ISO"
# Copie de travail du profil : syslinux n'affiche que le CP437, on y convertit ses menus.
profile=/work/profile
rm -rf "$profile" /work/iso
cp -a /orbe/archiso "$profile"
for cfg in "$profile"/syslinux/*.cfg; do
  iconv -f UTF-8 -t CP437 "$cfg" -o "$cfg.cp437" && mv "$cfg.cp437" "$cfg"
done
# Paquets optionnels (archiso/packages.optional) : ajoutés seulement s'ils sont disponibles,
# dans [orbe] ou dans les dépôts Arch. Les autres sont signalés.
if [[ -f /orbe/archiso/packages.optional ]]; then
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if compgen -G "$repo/$pkg-[0-9]*.pkg.tar.*" >/dev/null || pacman -Si "$pkg" >/dev/null 2>&1; then
      echo "$pkg" >> "$profile/packages.x86_64"
    else
      echo "ATTENTION : paquet optionnel $pkg indisponible, absent de l'ISO." >&2
    fi
  done < /orbe/archiso/packages.optional
fi
# Polices du thème GRUB, générées depuis les sources plutôt que versionnées.
bash /orbe/tools/make-grub-fonts.sh "$profile/grub/themes/orbe"
mkdir -p "$isodir"
rm -f "$isodir"/orbe-os-*.iso "$isodir"/orbe-os-*.iso.sha256
mkarchiso -v -r -w /work/iso -o "$isodir" "$profile"
cd "$isodir"
for iso in orbe-os-*.iso; do sha256sum "$iso" > "$iso.sha256"; done
ls -lh "$isodir"
