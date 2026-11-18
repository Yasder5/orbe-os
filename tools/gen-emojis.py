#!/usr/bin/env python3
"""Génère shell/launcher/emojis.json pour le lanceur (préfixe « : »).

Noms anglais Unicode (module unicodedata de Python), plus des mots-clés français pour les
émojis courants. Usage : python3 tools/gen-emojis.py (depuis la racine du dépôt).
"""
import json
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "shell/launcher/emojis.json"

RANGES = [(0x1F600, 0x1F64F), (0x1F900, 0x1F9FF), (0x1F300, 0x1F5FF), (0x1F680, 0x1F6FF),
          (0x1FA70, 0x1FAFF), (0x2600, 0x26FF), (0x2700, 0x27BF)]

# Mots-clés français (les émojis listés ici passent aussi en tête quand la recherche est vide).
FRENCH = {
    "😀": "sourire content", "😂": "rire larmes mdr", "🤣": "mort de rire", "😊": "sourire timide",
    "😍": "amoureux coeur yeux", "😘": "bisou", "😉": "clin d'oeil", "😎": "lunettes cool",
    "🤔": "réfléchir hmm", "😅": "gêne sueur", "😭": "pleurer triste", "😢": "triste larme",
    "😡": "colère énervé", "😱": "peur cri", "😴": "dormir sommeil", "🙃": "à l'envers",
    "🥲": "sourire triste", "🥳": "fête anniversaire", "🤯": "explosion choc", "😇": "ange",
    "🙂": "sourire léger", "😬": "grimace", "🤗": "câlin", "🤩": "étoiles waouh",
    "👍": "pouce oui ok bien", "👎": "pouce non", "👌": "ok parfait", "👏": "applaudir bravo",
    "🙏": "merci prier s'il te plaît", "💪": "force muscle", "👋": "salut coucou main",
    "✌": "paix victoire", "🤝": "poignée de main accord", "🫡": "salut respect",
    "❤": "coeur amour", "💔": "coeur brisé", "💯": "cent parfait", "🔥": "feu chaud",
    "✨": "étincelles brillant", "⭐": "étoile", "🎉": "fête bravo confettis", "🎁": "cadeau",
    "🎮": "manette jeu vidéo", "🕹": "joystick jeu", "🏆": "trophée coupe victoire",
    "🚀": "fusée lancement", "💡": "idée ampoule", "✅": "valide coche fait", "❌": "croix non erreur",
    "⚠": "attention avertissement", "📌": "épingle", "📎": "trombone", "💻": "ordinateur portable",
    "🖥": "écran ordinateur", "⌨": "clavier", "🖱": "souris", "🎧": "casque musique",
    "🎵": "musique note", "📷": "photo appareil", "☕": "café", "🍕": "pizza", "🍔": "burger",
    "🍺": "bière", "🍷": "vin", "🎂": "gâteau anniversaire", "🌙": "lune nuit", "☀": "soleil",
    "🌧": "pluie", "❄": "neige flocon froid", "⚡": "éclair rapide", "🌍": "terre monde",
    "🐱": "chat", "🐶": "chien", "👀": "yeux regarder", "🧠": "cerveau", "💀": "crâne mort",
    "🤖": "robot", "👻": "fantôme", "🙈": "singe yeux", "🎯": "cible", "📅": "calendrier date",
    "⏰": "réveil alarme", "🔒": "cadenas verrouillé", "🔑": "clé", "🛠": "outils", "🗑": "poubelle",
}


def main():
    entries, seen = [], set()
    for start, end in RANGES:
        for cp in range(start, end + 1):
            ch = chr(cp)
            try:
                name = unicodedata.name(ch).lower()
            except ValueError:
                continue
            if ch in seen:
                continue
            seen.add(ch)
            keywords = FRENCH.get(ch, "")
            # Anciens symboles (2600-27BF) : sélecteur VS16 pour la version émoji en couleur.
            if cp < 0x1F000:
                ch += "\ufe0f"
            entries.append({"e": ch, "n": name, "k": keywords})
    # Émojis avec mots-clés français d'abord : ce sont les plus courants.
    entries.sort(key=lambda x: 0 if x["k"] else 1)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(entries, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"{len(entries)} émojis écrits dans {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
