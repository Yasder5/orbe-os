#!/usr/bin/env bash
# Assemble le curseur Orbe : thème xcursor (xcursorgen) et thème hyprcursor (hyprcursor-util).
# Usage : build.sh DOSSIER_GENERE SORTIE   (DOSSIER_GENERE vient de generate.py)
# Résultat : SORTIE/Orbe/{index.theme,cursors/,manifest.hl,hyprcursors/}
set -euo pipefail
gen=$(readlink -f "$1") out=$(readlink -f "$2")
theme=$out/Orbe
mkdir -p "$theme/cursors"

# xcursor : un fichier par forme, les alias en liens symboliques.
for cfg in "$gen"/cfg/*.cfg; do
  name=$(basename "$cfg" .cfg)
  xcursorgen -p "$gen/png" "$cfg" "$theme/cursors/$name"
done
while read -r alias target; do
  ln -sfn "$target" "$theme/cursors/$alias"
done < "$gen/aliases.txt"
cat > "$theme/index.theme" <<'THEME'
[Icon Theme]
Name=Orbe
Comment=Curseur Orbe : noir, contour blanc cassé, point citron
THEME

# hyprcursor : dossier de travail (manifest + une description par forme), puis compilation.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
src=$work/Orbe
mkdir -p "$src/hyprcursors"
cat > "$src/manifest.hl" <<'MANIFEST'
name = Orbe
description = Curseur Orbe : noir, contour blanc cassé, point citron
version = 1.0
cursors_directory = hyprcursors
MANIFEST
for cfg in "$gen"/cfg/*.cfg; do
  name=$(basename "$cfg" .cfg)
  dir=$src/hyprcursors/$name
  mkdir -p "$dir"
  overrides=$(awk -v t="$name" '$2 == t { printf "%s%s", sep, $1; sep = ";" }' "$gen/aliases.txt")
  # Point actif en fraction de l'image, lu sur la plus grande taille.
  read -r size hx hy _ < <(sort -n "$cfg" | tail -n1)
  {
    echo "resize_algorithm = bilinear"
    echo "hotspot_x = $(awk -v a="$hx" -v s="$size" 'BEGIN { printf "%.3f", a / s }')"
    echo "hotspot_y = $(awk -v a="$hy" -v s="$size" 'BEGIN { printf "%.3f", a / s }')"
    [[ -n $overrides ]] && echo "define_override = $overrides"
    while read -r s _ _ png delay; do
      cp "$gen/png/$png" "$dir/"
      echo "define_size = $s, $png${delay:+, $delay}"
    done < "$cfg"
  } > "$dir/meta.hl"
done
mkdir -p "$work/out"
hyprcursor-util --create "$src" -o "$work/out" >/dev/null
cp -r "$work"/out/*/manifest.hl "$work"/out/*/hyprcursors "$theme/"
echo "Curseur Orbe : $(ls "$theme/cursors" | wc -l) noms xcursor, $(ls "$theme/hyprcursors" | wc -l) formes hyprcursor"
