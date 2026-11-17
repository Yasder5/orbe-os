#!/usr/bin/env bash
# Construit les paquets Orbe puis l'ISO Orbe OS dans un conteneur Arch privilégié.
# Usage : ./build.sh [--fast] [--packages-only]
#   --fast           compression légère de l'ISO, pour les essais
#   --packages-only  construit seulement le dépôt [orbe]
# Variables utiles :
#   ORBE_IMAGE      image Docker de base (défaut : archlinux:latest)
#   ORBE_MIRROR     miroir Arch (défaut : https://geo.mirror.pkgbuild.com/$repo/os/$arch)
#   ORBE_EXTRA_CA   certificat d'autorité à ajouter dans le conteneur (proxy d'entreprise)
# Résultat : out/iso/orbe-os-AAAA.MM.JJ-x86_64.iso et son .sha256, journal dans out/build.log
set -euo pipefail

ROOT=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cd "$ROOT"

fast=0
packages_only=0
for arg in "$@"; do
  case "$arg" in
    --fast) fast=1 ;;
    --packages-only) packages_only=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $arg (voir --help)" >&2; exit 2 ;;
  esac
done

die() { echo "ERREUR : $*" >&2; exit 1; }
log() { printf '\n==> %s\n' "$*"; }

command -v docker >/dev/null || die "Docker absent (voir tools/preflight.sh)."
docker info >/dev/null 2>&1 || die "Docker inaccessible : démon arrêté ou utilisateur hors du groupe docker."
case "$ROOT" in /mnt/*) die "Le dépôt est sous /mnt : déplace-le dans le système de fichiers Linux (~/orbe-os)." ;; esac

image=${ORBE_IMAGE:-archlinux:latest}

# Image de base : archlinux:latest, sinon l'archive bootstrap officielle d'Arch importée dans Docker
# (utile quand Docker Hub limite les téléchargements anonymes).
ensure_image() {
  docker image inspect "$image" >/dev/null 2>&1 && return
  log "Téléchargement de l'image $image"
  docker pull "$image" && return
  [[ -n "${ORBE_IMAGE:-}" ]] && die "Impossible de récupérer $image."
  image=orbe-archlinux-bootstrap:latest
  docker image inspect "$image" >/dev/null 2>&1 && return
  log "Docker Hub indisponible : import de l'archive bootstrap officielle d'Arch"
  command -v zstd >/dev/null || die "zstd requis pour l'import (sudo apt install -y zstd)."
  local tmp mirror=https://geo.mirror.pkgbuild.com/iso/latest
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL -o "$tmp/bootstrap.tar.zst" "$mirror/archlinux-bootstrap-x86_64.tar.zst"
  curl -fsSL -o "$tmp/sha256sums.txt" "$mirror/sha256sums.txt"
  (cd "$tmp" && grep ' archlinux-bootstrap-x86_64.tar.zst$' sha256sums.txt | sed 's/archlinux-bootstrap-x86_64/bootstrap/' | sha256sum -c --quiet -) \
    || die "Somme de contrôle de l'archive bootstrap invalide."
  mkdir "$tmp/root"
  tar --zstd -xpf "$tmp/bootstrap.tar.zst" -C "$tmp/root" --numeric-owner 2>/dev/null
  tar -C "$tmp/root/root.x86_64" --numeric-owner -c . | docker import - "$image" >/dev/null
}
ensure_image

docker_args=(--rm --privileged
  -v "$ROOT:/orbe"
  -v orbe-pacman-cache:/var/cache/pacman/pkg
  -v orbe-work:/work
  -e ORBE_FAST="$fast"
  -e ORBE_PACKAGES_ONLY="$packages_only"
  -e ORBE_MIRROR="${ORBE_MIRROR:-}"
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)")

# Proxy HTTPS de la machine hôte : le conteneur partage alors le réseau de l'hôte.
if [[ -n "${HTTPS_PROXY:-}${https_proxy:-}" ]]; then
  docker_args+=(--network host -e HTTPS_PROXY="${HTTPS_PROXY:-$https_proxy}" -e https_proxy="${https_proxy:-$HTTPS_PROXY}")
fi
if [[ -n "${ORBE_EXTRA_CA:-}" ]]; then
  [[ -f "$ORBE_EXTRA_CA" ]] || die "ORBE_EXTRA_CA ne pointe pas vers un fichier : $ORBE_EXTRA_CA"
  docker_args+=(-v "$(readlink -f "$ORBE_EXTRA_CA"):/run/orbe-extra-ca.crt:ro")
fi

mkdir -p out
log "Construction dans le conteneur ($image), journal : out/build.log"
start=$(date +%s)
docker run "${docker_args[@]}" "$image" bash /orbe/tools/build-in-container.sh 2>&1 | tee out/build.log
status=${PIPESTATUS[0]}
log "Terminé en $(( ($(date +%s) - start) / 60 )) min, code $status"
[[ "$status" -eq 0 ]] && ls -lh out/iso/*.iso 2>/dev/null
exit "$status"
