# Préparer Forgejo pour Orbe OS : instructions pour Claude (serveur de Yass)

Tu tournes sur le serveur de Yass, où Forgejo sert déjà de serveur git. Ta mission : préparer
Forgejo pour qu'une **autre session Claude Code, dans le cloud d'Anthropic** (claude.ai/code),
puisse y publier le projet Orbe OS. Tu ne publies rien toi-même : tu prépares le terrain et tu
écris une note de passation.

## Contexte

- **Orbe OS** : distribution Arch Linux de Yass, orientée jeu, pour lui et quelques potes.
  Le code est sur GitHub, public : https://github.com/Yasder5/orbe-os
- **La session cloud** construit l'ISO et le code. Elle n'a aucun accès à ton réseau local. Elle
  sort par un proxy HTTPS qui impose :
  - **HTTPS sur le port 443 seulement**, vers un **nom de domaine public** avec un **certificat
    valide** (pas d'adresse IP, pas de nom interne, pas de certificat autosigné) ;
  - **pas de SSH** : le git passe par HTTPS ;
  - l'hôte doit être ajouté à la liste réseau de son environnement, ce que Yass approuve de son côté.
- **Authentification de la session cloud** : un jeton Forgejo que Yass saisit lui-même dans un
  formulaire sécurisé de claude.ai. Le proxy l'ajoute aux requêtes en authentification « basic »
  (nom du compte + jeton comme mot de passe), pour git comme pour l'API. **Le jeton ne passe
  jamais par le chat, ni par toi, ni par un fichier.**

## Ce que la session cloud devra pouvoir publier

| Quoi | Taille | Comment |
|---|---|---|
| Dépôt git `orbe-os`, branche `main` | quelques Mo, historique complet | `git push` en HTTPS |
| ISO d'installation, à chaque version | **2,4 à 2,7 Gio en un seul fichier**, plus son `.sha256` | registre de paquets « generic » de Forgejo (conseillé) ou pièce jointe de version |
| Plus tard, **seulement si Yass le demande** : dépôt pacman `[orbe]` | environ 200 Mo, 15 paquets | registre Arch de Forgejo s'il existe dans sa version, sinon paquets « generic » |

La branche `iso` de GitHub (l'ISO découpée en morceaux de 95 Mo) n'a pas à être copiée sur Forgejo.

## Règles

- Réponds en français, de façon concise.
- **Commence en lecture seule.** Avant toute modification (fichier `app.ini`, proxy inverse,
  DNS, pare-feu, redémarrage d'un service, création de compte), explique ce que tu vas faire et
  **attends l'accord de Yass**.
- Avant de modifier un fichier de configuration, fais-en une copie datée à côté
  (`app.ini.avant-orbe-AAAAMMJJ`).
- **Aucun secret** (jeton, mot de passe, clé) dans un fichier, une commande que tu lances ou le
  chat. Ne lis pas les secrets existants de `app.ini` (`SECRET_KEY`, `INTERNAL_TOKEN`,
  `JWT_SECRET`, mots de passe de base de données) : ne les affiche pas.
- Si `sudo` demande un mot de passe, donne à Yass la commande exacte à lancer avec `! sudo …`.
- Arrête un processus par son PID, jamais avec `pkill -f`.
- Ne touche ni aux autres dépôts, ni aux autres comptes, ni aux autres sites du serveur.
- Le serveur sort peut-être d'une maintenance : si quelque chose a l'air cassé, signale-le avant
  de continuer.

## Étapes

### 1. État des lieux (lecture seule)

Relève et présente à Yass :
- la version de Forgejo (`forgejo --version`, ou `/api/v1/version`) et son mode d'installation
  (paquet, binaire et service systemd, Docker Compose…) ;
- l'emplacement de `app.ini` et ses réglages utiles : `[server] ROOT_URL`, `[packages]`,
  `[attachment]`, `[repository.upload]` ;
- le proxy inverse devant Forgejo (nginx, Caddy, Traefik, Apache…), son fichier pour ce site et
  la gestion du certificat ;
- **comment le serveur est joint depuis Internet** : nom de domaine, enregistrement DNS, IP
  publique ou CGNAT, redirection de port sur la box, Cloudflare (proxy orange ou DNS seul),
  tunnel Cloudflare, Tailscale Funnel… ;
- l'espace disque libre là où Forgejo range ses paquets et pièces jointes (prévoir au moins
  10 Go, plus 3 Go par ISO gardée) ;
- les comptes et organisations existants (noms seulement).

### 2. Accès depuis Internet en HTTPS

Vérifie que `https://NOM-PUBLIC/api/v1/version` répond avec un certificat valide **par le nom
public**, pas par `localhost`. Pièges à signaler :
- **Cloudflare en mode proxy (nuage orange) ou tunnel Cloudflare** : les envois sont limités à
  100 Mo par requête sur l'offre gratuite. L'ISO ne passera pas. Solutions à proposer à Yass :
  un sous-domaine en « DNS seul » qui pointe directement sur le serveur, ou une autre exposition.
- Pas d'IP publique (CGNAT) : il faut une exposition (tunnel, VPS relais, Tailscale Funnel…).
  Présente les options à Yass, ne choisis pas seul.

### 3. Envois de plusieurs gigaoctets

- **Proxy inverse** :
  - nginx : pour ce site, `client_max_body_size 0;` (ou au moins `4G`),
    `proxy_request_buffering off;`, `proxy_read_timeout` et `proxy_send_timeout` d'au moins `900s` ;
  - Caddy : pas de limite par défaut ; vérifie qu'aucune directive `request_body` n'en ajoute une ;
  - Traefik, Apache : cherche l'équivalent (taille du corps et délais).
- **Forgejo** (`app.ini`) :
  - `[packages] ENABLED = true`, et `LIMIT_SIZE_GENERIC` à `-1` ou au moins `4 GiB` ;
  - si Yass préfère les pièces jointes de version : `[attachment] MAX_SIZE` (en Mo) d'au moins
    `4096`, et `ALLOWED_TYPES` qui accepte les `.iso`.
- Redémarre Forgejo et recharge le proxy **seulement avec l'accord de Yass**.

Le registre « generic » est conseillé pour l'ISO : envoi par un simple `PUT`, versions rangées,
adresses stables :
`https://NOM-PUBLIC/api/packages/PROPRIETAIRE/generic/orbe-os/VERSION/orbe-os-VERSION-x86_64.iso`

### 4. Compte, organisation et dépôt

Propose ceci à Yass (il peut préférer son propre compte) :
- un compte **`orbe-bot`**, sans droits d'administration, réservé à la session cloud ;
- une organisation **`orbe`** avec une équipe « publication » qui contient `orbe-bot`, avec
  l'écriture sur les dépôts et sur les paquets ;
- un dépôt **`orbe/orbe-os` vide** : sans README, licence ni `.gitignore`, pour que l'historique
  existant puisse y être poussé tel quel. **Demande à Yass s'il le veut privé ou public.** Le
  dépôt GitHub est public, mais l'ISO est pour lui et ses potes ;
- pas de miroir automatique depuis GitHub sur ce dépôt : la session cloud y poussera directement ;
- protection de `main` contre les `push --force`, si Yass le souhaite.

### 5. Le jeton (c'est Yass qui le fait)

Ne crée pas le jeton toi-même et n'en affiche jamais. Explique à Yass :
1. se connecter à Forgejo avec `orbe-bot` ;
2. aller dans Paramètres, Applications, et générer un jeton avec les droits `write:repository`
   et `write:package` (rien d'autre) ;
3. garder le jeton pour le formulaire sécurisé de la session cloud. Il ne doit être collé ni ici,
   ni dans le chat de la session cloud.

### 6. Test d'un gros envoi

Le script `tester-envoi.sh`, à côté de ce fichier, envoie un fichier de 3 Gio vers le registre
« generic » par l'adresse publique, puis le supprime. Le jeton y est demandé sans s'afficher.
**Yass le lance lui-même, dans un terminal à part** (pas avec `!`, pour que le jeton ne passe pas
par toi) :

```bash
bash tester-envoi.sh https://NOM-PUBLIC orbe orbe-bot
```

Réponse attendue : `201`. Un `413` vient d'une limite de taille (proxy ou Forgejo), un `401`
d'un jeton ou d'un nom de compte faux, un `404` d'un registre désactivé ou d'un propriétaire faux.
Corrige avec Yass jusqu'à obtenir `201`. Si le serveur est derrière Cloudflare en mode proxy, ce
test ne prouve rien tant que l'envoi ne passe pas réellement par le nom public.

### 7. Passation

Écris `~/orbe-forgejo-passation.md`, **sans aucun secret**, puis montre-le à Yass pour qu'il le
colle à la session cloud :
- adresse publique de Forgejo et version ;
- propriétaire et dépôt (`orbe/orbe-os`), privé ou public, adresse HTTPS du dépôt ;
- nom du compte de publication (`orbe-bot`) et droits du jeton ;
- choix pour l'ISO (registre « generic » ou pièces jointes) et adresse type d'un fichier ;
- limites en place : proxy, `LIMIT_SIZE_GENERIC`, `[attachment] MAX_SIZE`, délais ;
- exposition (domaine, Cloudflare ou non) et résultat du test d'envoi de 3 Gio ;
- registre Arch disponible ou non dans cette version de Forgejo (pour `[orbe]`, plus tard) ;
- ce qui reste à faire ou à décider par Yass.

## Pour information : ce que fera ensuite la session cloud

1. Ajouter le nom public de Forgejo à la liste réseau de son environnement (Yass approuve).
2. Demander le jeton à Yass par le formulaire sécurisé (type « basic », compte `orbe-bot`).
3. Ajouter le remote `forgejo`, pousser `main`, puis envoyer l'ISO et son `.sha256` dans le
   registre « generic », version par version.
