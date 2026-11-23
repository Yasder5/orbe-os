#!/usr/bin/env bash
# Vérifie qu'un fichier de 3 Gio (la taille d'une ISO d'Orbe OS) passe jusqu'au registre de
# paquets « generic » de Forgejo par son adresse publique, puis le supprime.
#
# Usage : bash tester-envoi.sh https://git.exemple.fr PROPRIETAIRE [COMPTE]
#   PROPRIETAIRE : compte ou organisation qui recevra les paquets (ex. orbe)
#   COMPTE       : compte qui envoie (défaut : orbe-bot)
#
# Le jeton est demandé sans s'afficher. Il n'est ni écrit sur le disque ni passé en argument
# (invisible dans la liste des processus).
set -euo pipefail

url=${1:?"adresse publique de Forgejo, ex. https://git.exemple.fr"}
url=${url%/}
proprio=${2:?"propriétaire des paquets (compte ou organisation)"}
compte=${3:-orbe-bot}
hote=${url#*://}
hote=${hote%%/*}
hote=${hote%%:*}

read -rsp "Jeton Forgejo de $compte : " jeton
echo
[[ -n $jeton ]] || { echo "Jeton vide." >&2; exit 1; }

# Identifiants passés à curl par un descripteur, jamais par la ligne de commande.
identifiants() {
  printf 'machine %s login %s password %s\n' "$hote" "$compte" "$jeton"
}

fichier=$(mktemp --suffix=.bin)
trap 'rm -f "$fichier"' EXIT
truncate -s 3G "$fichier"

paquet="$url/api/packages/$proprio/generic/orbe-test/0"
echo "Envoi de 3 Gio vers $paquet/essai.bin (plusieurs minutes possibles)…"
resultat=$(curl -sS -o /dev/null --netrc-file <(identifiants) --upload-file "$fichier" \
  -w '%{http_code} %{time_total} %{speed_upload}' "$paquet/essai.bin") || true
read -r code duree vitesse <<< "${resultat:-000 0 0}"
echo "Réponse : $code en ${duree%.*} s ($((${vitesse%.*} / 1048576)) Mo/s)"
case $code in
  201) echo "Envoi accepté." ;;
  413) echo "Trop gros : limite du proxy inverse ou de Forgejo (LIMIT_SIZE_GENERIC)." ;;
  401|403) echo "Refusé : jeton, nom de compte ou droits (write:package) à vérifier." ;;
  404) echo "Introuvable : registre de paquets désactivé ou propriétaire inconnu." ;;
  000) echo "Pas de réponse : connexion coupée (délai du proxy, Cloudflare, certificat…)." ;;
  *) echo "Réponse inattendue." ;;
esac

if [[ $code == 201 ]]; then
  suppression=$(curl -sS -o /dev/null --netrc-file <(identifiants) -X DELETE -w '%{http_code}' "$paquet") || true
  echo "Suppression du paquet d'essai : ${suppression:-échec} (204 attendu)"
fi
