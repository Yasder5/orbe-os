#!/usr/bin/env bash
# Compile les shaders d'Orbe Shell (shell/shaders/*.frag) au format .qsb de Qt 6.
# Lancé dans un conteneur Arch avec qt6-shadertools (build-in-container.sh, shell-preview.sh).
# Usage : build-shaders.sh DOSSIER_SHADERS
set -euo pipefail

dir=${1:?dossier des shaders}
qsb=/usr/lib/qt6/bin/qsb
[[ -x "$qsb" ]] || { echo "qsb absent (paquet qt6-shadertools)" >&2; exit 1; }
for frag in "$dir"/*.frag; do
  [[ -f "$frag" ]] || continue
  # GLSL pour OpenGL et OpenGL ES, HLSL et MSL au cas où Qt choisit un autre moteur de rendu.
  "$qsb" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$frag.qsb" "$frag"
done
