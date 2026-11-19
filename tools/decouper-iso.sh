#!/usr/bin/env bash
# Découpe l'ISO en morceaux, avec les sommes SHA-256 de l'ISO entière et de chaque morceau.
# Usage : [TAILLE=95M] tools/decouper-iso.sh [ISO]   (défaut : la plus récente de out/iso, morceaux de 1 Gio)
# 1G convient aux versions GitHub (2 Gio par fichier au plus), 95M à une branche git (100 Mo par fichier).
# Résultat : out/morceaux/<iso>.part-aa, -ab, ... et SHA256SUMS
#
# Recoller sous Linux :   cat orbe-os-*.iso.part-* > orbe-os.iso && sha256sum -c SHA256SUMS --ignore-missing
# Recoller sous Windows : cmd /c copy /b "orbe-os-AAAA.MM.JJ-x86_64.iso.part-aa"+"...part-ab"+"...part-ac" orbe-os.iso
set -euo pipefail
ROOT=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
iso=${1:-$(ls -t "$ROOT"/out/iso/*.iso | head -n1)}
name=$(basename "$iso")
out=$ROOT/out/morceaux
rm -rf "$out" && mkdir -p "$out"
split -b "${TAILLE:-1G}" -a 2 "$iso" "$out/$name.part-"
(cd "$(dirname "$iso")" && sha256sum "$name") > "$out/SHA256SUMS"
(cd "$out" && sha256sum "$name".part-* >> SHA256SUMS)
ls -lh "$out"
