#!/usr/bin/env bash
# Convertit Archivo et JetBrains Mono au format de police de GRUB (.pf2).
# Lancé dans le conteneur de build (grub, freetype2, python-fonttools, ttf-jetbrains-mono).
# Usage : make-grub-fonts.sh DOSSIER_DU_THEME
set -euo pipefail

dest=$1
archivo="/orbe/themes/fonts/Archivo[wdth,wght].ttf"
mono=/usr/share/fonts/TTF/JetBrainsMono-Regular.ttf
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Archivo est une police variable : on en fige deux graisses (400 et 600) à largeur normale.
fonttools varLib.instancer "$archivo" wght=400 wdth=100 -q -o "$tmp/Archivo-Regular.ttf"
fonttools varLib.instancer "$archivo" wght=600 wdth=100 -q -o "$tmp/Archivo-SemiBold.ttf"

# Le nom GRUB d'une police est « famille style taille » : « Archivo Regular 22 »,
# « ArchivoSemiBold Regular 48 », « JetBrains Mono Regular 16 ».
mk() { grub-mkfont -s "$1" -n "$2" -o "$dest/$3" "$4" 2>/dev/null; }
mk 22 Archivo archivo-regular-22.pf2 "$tmp/Archivo-Regular.ttf"
mk 22 ArchivoSemiBold archivo-semibold-22.pf2 "$tmp/Archivo-SemiBold.ttf"
mk 48 ArchivoSemiBold archivo-semibold-48.pf2 "$tmp/Archivo-SemiBold.ttf"
mk 16 "JetBrains Mono" jetbrains-mono-16.pf2 "$mono"
ls "$dest"/*.pf2 >/dev/null
