#!/usr/bin/env bash
# Envoie une ISO (par défaut la plus récente de out/iso) et son .sha256 dans le registre de
# paquets « generic » du Forgejo de Yass, puis vérifie l'empreinte calculée par le serveur.
#
# Adresse : variable ORBE_FORGEJO (ex. https://git.exemple.fr), sinon celle du remote git
# « forgejo ». Propriétaire des paquets : ORBE_FORGEJO_PROPRIO (défaut : orbe).
# Authentification : dans la session cloud, le proxy ajoute le jeton du compte orbe-bot ; ailleurs,
# passer les identifiants par ~/.netrc (jamais en argument).
#
# Usage : tools/publier-iso.sh [ISO]
set -euo pipefail
cd "$(dirname "$0")/.."

iso=${1:-$(ls -t out/iso/orbe-os-*-x86_64.iso 2>/dev/null | head -n1)}
[[ -f $iso ]] || { echo "Aucune ISO dans out/iso." >&2; exit 1; }
nom=$(basename "$iso")
version=${nom#orbe-os-}
version=${version%-x86_64.iso}

base=${ORBE_FORGEJO:-$(git remote get-url forgejo 2>/dev/null | sed -E 's#^(https://[^/]+)/.*#\1#' || true)}
[[ $base == https://* ]] || { echo "Adresse de Forgejo inconnue : définir ORBE_FORGEJO ou le remote « forgejo »." >&2; exit 1; }
proprio=${ORBE_FORGEJO_PROPRIO:-orbe}
paquet="$base/api/packages/$proprio/generic/orbe-os/$version"
netrc=()
[[ -f ~/.netrc ]] && netrc=(--netrc-optional)

[[ -f $iso.sha256 ]] || (cd "$(dirname "$iso")" && sha256sum "$nom" > "$nom.sha256")
(cd "$(dirname "$iso")" && sha256sum -c --quiet "$nom.sha256") || { echo "L'ISO ne correspond pas à son .sha256." >&2; exit 1; }

for f in "$iso" "$iso.sha256"; do
  echo "Envoi de $(basename "$f") ($(du -h "$f" | cut -f1))…"
  code=$(curl -sS "${netrc[@]}" -o /dev/null -w '%{http_code}' -T "$f" "$paquet/$(basename "$f")")
  case $code in
    201) ;;
    409) echo "Déjà présent dans la version $version : supprimer cette version dans Forgejo pour la remplacer." >&2; exit 1 ;;
    401|403) echo "Refusé ($code) : jeton absent, faux ou sans le droit write:package." >&2; exit 1 ;;
    413) echo "Trop gros (413) : limite du proxy inverse ou de Forgejo." >&2; exit 1 ;;
    *) echo "Échec de l'envoi ($code)." >&2; exit 1 ;;
  esac
done

attendu=$(cut -d' ' -f1 "$iso.sha256")
recu=$(curl -sS "${netrc[@]}" "$base/api/v1/packages/$proprio/generic/orbe-os/$version/files" \
  | python3 -c 'import json, sys; print(next((f["sha256"] for f in json.load(sys.stdin) if f["name"] == sys.argv[1]), ""))' "$nom")
[[ $recu == "$attendu" ]] || { echo "Empreinte différente côté serveur : $recu" >&2; exit 1; }
echo "Publié et vérifié (sha256 $attendu)."
echo "Téléchargement : $paquet/$nom"
