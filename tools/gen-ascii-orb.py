#!/usr/bin/env python3
"""Génère le logo ASCII d'Orbe pour fastfetch (themes/terminal/orbe-logo.txt).

Même sphère de particules que les visuels : points discrets ($1, gris) et points accent ($2).
Usage : python3 tools/gen-ascii-orb.py (depuis la racine du dépôt).
"""
import math
import random
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "themes/terminal/orbe-logo.txt"
W, H, N = 34, 15, 230          # caractères (une cellule fait environ deux fois plus haut que large)
random.seed(7)
grid = [[(" ", -2.0, 0) for _ in range(W)] for _ in range(H)]
golden = math.pi * (1 + 5 ** 0.5)
yaw, tilt = 0.6, -0.42
for i in range(N):
    phi = math.acos(1 - 2 * (i + 0.5) / N)
    th = golden * (i + 0.5)
    x, y, z = math.cos(th) * math.sin(phi), math.sin(th) * math.sin(phi), math.cos(phi)
    x1, z1 = x * math.cos(yaw) + z * math.sin(yaw), -x * math.sin(yaw) + z * math.cos(yaw)
    y2, z2 = y * math.cos(tilt) - z1 * math.sin(tilt), y * math.sin(tilt) + z1 * math.cos(tilt)
    cx = round((x1 + 1) / 2 * (W - 1))
    cy = round((y2 + 1) / 2 * (H - 1))
    accent = random.random() < 0.12
    if z2 < grid[cy][cx][1]:
        continue
    if accent and z2 > -0.2:
        grid[cy][cx] = ("●", z2, 2)
    elif z2 > 0.35:
        grid[cy][cx] = ("•", z2, 1)
    else:
        grid[cy][cx] = ("·", z2, 1)
lines = []
for row in grid:
    out, color = "", 0
    for ch, _, c in row:
        if ch != " " and c != color:
            out += f"${c}"
            color = c
        out += ch
    lines.append(out.rstrip())
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(OUT.read_text().replace("$1", "").replace("$2", ""))
