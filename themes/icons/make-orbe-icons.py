#!/usr/bin/env python3
"""Thème d'icônes « Orbe » : Papirus-Dark, avec les dossiers recolorés en citron.

Usage : python3 make-orbe-icons.py SORTIE [/usr/share/icons]
Lit Papirus et Papirus-Dark installés (paquet papirus-icon-theme, GPL-3.0) et écrit dans SORTIE
un thème qui hérite de Papirus-Dark et ne remplace que les icônes de dossiers de la couleur par
défaut (bleu). Les icônes produites restent sous GPL-3.0, comme Papirus.
"""
import os
import re
import sys
from pathlib import Path

# Bleu de Papirus -> palette Orbe (avant, arrière, pictogramme posé sur le dossier).
COLORS = {
    "#5294e2": "#d3fd50",
    "#4877b1": "#a3c93a",
    "#1d344f": "#2a3510",
}


def main():
    out = Path(sys.argv[1])
    base = Path(sys.argv[2] if len(sys.argv) > 2 else "/usr/share/icons")
    dark = base / "Papirus-Dark"
    pattern = re.compile("|".join(map(re.escape, COLORS)), re.IGNORECASE)
    dirs = []
    for size_dir in sorted(dark.iterdir()):
        places = size_dir / "places"
        # Les variantes @2x sont des liens vers la taille simple : traitées plus bas.
        if size_dir.name.endswith("@2x") or not places.is_dir():
            continue
        count = 0
        for icon in places.iterdir():
            # Dossiers « par défaut » : liens vers folder-blue*.svg (folder.svg, user-home.svg...).
            if not icon.is_symlink():
                continue
            target = os.readlink(icon)
            if not Path(target).name.startswith("folder-blue"):
                continue
            svg = (places / target).resolve().read_text(encoding="utf-8")
            dest = out / size_dir.name / "places" / icon.name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(pattern.sub(lambda m: COLORS[m.group(0).lower()], svg), encoding="utf-8")
            count += 1
        if count:
            dirs.append(size_dir.name)

    # index.theme : reprend la description des dossiers « places » de Papirus-Dark.
    index = (dark / "index.theme").read_text(encoding="utf-8")
    sections = {}
    for block in re.split(r"\n(?=\[)", index):
        m = re.match(r"\[([^\]]+)\]", block)
        if m:
            sections[m.group(1)] = block.strip()
    entries = [key for d in dirs for key in (f"{d}/places", f"{d}@2x/places") if key in sections]
    lines = [
        "[Icon Theme]",
        "Name=Orbe",
        "Comment=Papirus-Dark, dossiers aux couleurs d'Orbe",
        "Inherits=Papirus-Dark,breeze-dark,hicolor",
        "Directories=" + ",".join(entries),
        "",
    ]
    for key in entries:
        block = sections[key].splitlines()[1:]
        lines.append(f"[{key}]")
        lines.extend(block)
        lines.append("")
    (out / "index.theme").write_text("\n".join(lines), encoding="utf-8")
    # Les variantes @2x de Papirus-Dark sont des liens vers la taille simple : idem ici.
    for d in dirs:
        link = out / f"{d}@2x"
        if f"{d}@2x/places" in sections and not link.exists():
            link.symlink_to(d)
    print(f"Orbe : {len(entries)} dossiers d'icônes")


if __name__ == "__main__":
    main()
