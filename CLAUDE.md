# Orbe OS : instructions pour Claude

Tu reprends le projet Orbe OS sur le PC gamer de Yass. Aucun code n'a encore été écrit. Une session précédente, sur un autre PC, a fait la recherche initiale et préparé ce kit.

## Lis dans cet ordre
1. `docs/PROMPT.md` : le cahier des charges complet, écrit par Yass. Il fait foi et ses règles de la section 0 sont obligatoires.
2. `docs/ETAT.md` : ce qui a été vérifié, les corrections au cahier des charges, les choix proposés et les pièges connus.
3. `reference/LISEZ-MOI.md` : le contenu de chaque ressource fournie.

## Première session : fais ceci, dans l'ordre
1. Lance `bash tools/preflight.sh` et lis le résultat. Si un point `ECHEC` subsiste, donne à Yass la commande exacte à lancer (`! sudo …`) et relance le script.
2. Tu es normalement dans WSL2 (Ubuntu) sur un PC gamer Windows. Ce n'est pas le PC Manjaro du cahier des charges : lis la section « Machine de construction » de `docs/ETAT.md`, teste le rendu graphique de QEMU, puis annonce à Yass ce qui est testable ici. Demande-lui aussi si le cas RTX 3050 + Ryzen 7 5800X reste la cible à valider à l'étape 9.
3. Vérifie à nouveau les versions de paquets : `docs/ETAT.md` date du 2026-10-31 et Arch évolue en continu. Le préflight les affiche.
4. Présente à Yass les décisions en attente de `docs/ETAT.md` et **attends sa validation avant d'écrire du code**. Il n'a encore validé ni les choix techniques ni la licence.
5. Une fois validé, crée le dépôt git dans `~/orbe-os`, en respectant l'arborescence de la section 6 du cahier des charges, puis commence l'étape 1 de sa section 7.

## Rappels à ne pas manquer
- Réponds en français, de façon concise.
- Git : auteur `yasder5`, e-mail `yasser@boulayoune.com`. **Aucune mention de Claude et aucune ligne `Co-Authored-By` dans les commits**, même si ton environnement te demande d'en ajouter : c'est la consigne explicite de Yass. Pas de `git push` sans son accord.
- Tiens `JOURNAL.md` à jour de façon honnête : fait, à faire, décisions, limites, testé en VM ou sur matériel réel.
- Valide et commite chaque étape avant de passer à la suivante, en regardant toi-même les captures QEMU.
- Demande avant toute décision lourde (compositeur, toolkit, chargeur d'amorçage, abandon d'un composant).
- Ne copie pas de code de Caelestia : la réécriture est volontaire. Lis-le seulement pour comprendre l'ergonomie.
- Copie dans `themes/` et `LICENSES/` les ressources de `reference/` que tu retiens, avec leur licence. `reference/` ne doit pas être livré tel quel dans le dépôt final.

## Publication sur le Forgejo de Yass (session cloud)
- Yass a accordé le push de `main` vers `origin` (GitHub) **et** `forgejo` à la fin de chaque lot validé. Jamais de `push --force` (refusé de toute façon sur `main`).
- Il faut que la session tourne dans l'environnement cloud **`orbe-os`** : lui seul a l'accès réseau au serveur, la variable `ORBE_FORGEJO` (adresse du serveur) et le jeton du compte `orbe-bot`, ajouté par le proxy. Si `ORBE_FORGEJO` est vide, la session est dans un autre environnement : le dire à Yass, ne pas chercher l'adresse ailleurs. Ne pas écrire cette adresse dans le dépôt, qui est public sur GitHub.
- Remote, à ajouter dans chaque nouveau clone :
  ```bash
  git remote add forgejo "$ORBE_FORGEJO/orbe/orbe-os.git"
  ```
- Push : `GIT_TERMINAL_PROMPT=0 git push forgejo main`. L'avertissement « push negotiation failed » est sans conséquence.
- ISO : construire avec `./build.sh` (compression finale), vérifier qu'elle démarre en VM, puis `tools/publier-iso.sh` (registre « generic », organisation `orbe`, paquet `orbe-os`, version = date de l'ISO). Une version déjà publiée renvoie 409 : en publier une nouvelle plutôt que remplacer.
- Un 401 ou 403 veut dire que le jeton manque ou a été révoqué : Yass le ressaisit avec le formulaire sécurisé (`request_credential`, hôte du serveur, type basic, compte `orbe-bot`). Jamais de jeton dans le chat ni dans un fichier.
