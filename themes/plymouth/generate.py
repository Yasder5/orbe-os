#!/usr/bin/env python3
"""Thème Plymouth « orbe » : l'orbe de particules se forme, puis tourne lentement.

Usage : python3 generate.py SORTIE   (demande Pillow et numpy)
Écrit les images (formation, rotation, champ de mot de passe) à côté de orbe.script et orbe.plymouth.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

TEXT = (245, 245, 240)
MUTED = (143, 143, 138)
ACCENT = (211, 253, 80)
SURFACE = (18, 18, 18)
LINE = (38, 38, 36)
SIZE = 320
COUNT = 340
FORM = 36    # images de formation
LOOP = 90    # images d'un tour complet
SS = 2


def sphere(n):
    i = np.arange(n) + 0.5
    phi = np.arccos(1 - 2 * i / n)
    theta = np.pi * (1 + 5 ** 0.5) * i
    return np.stack([np.cos(theta) * np.sin(phi), np.sin(theta) * np.sin(phi), np.cos(phi)], axis=1)


def rot(p, yaw, tilt):
    cy, sy, ct, st = np.cos(yaw), np.sin(yaw), np.cos(tilt), np.sin(tilt)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rx = np.array([[1, 0, 0], [0, ct, -st], [0, st, ct]])
    return p @ ry.T @ rx.T


def render(points, accent, alpha):
    w = SIZE * SS
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    glow = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    d, g = ImageDraw.Draw(img), ImageDraw.Draw(glow)
    radius = w * 0.40
    for idx in np.argsort(points[:, 2]):
        x, y, z = points[idx]
        depth = min(max((z + 1) / 2, 0), 1)
        px, py = w / 2 + x * radius, w / 2 + y * radius
        a = alpha[idx] * (0.25 + 0.75 * depth)
        if accent[idx]:
            r = SS * 2.6 * (0.6 + 0.4 * depth)
            d.ellipse((px - r, py - r, px + r, py + r), fill=ACCENT + (int(255 * a),))
            rg = r * 3
            g.ellipse((px - rg, py - rg, px + rg, py + rg), fill=ACCENT + (int(70 * a),))
        else:
            r = SS * 1.5 * (0.6 + 0.4 * depth)
            d.ellipse((px - r, py - r, px + r, py + r), fill=TEXT + (int(200 * a),))
    glow = glow.filter(ImageFilter.GaussianBlur(SS * 6))
    glow.alpha_composite(img)
    return glow.resize((SIZE, SIZE), Image.LANCZOS)


def ease(t):
    return 1 - (1 - t) ** 3


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(7)
    base = sphere(COUNT) + rng.normal(scale=0.018, size=(COUNT, 3))
    accent = rng.random(COUNT) < 0.1
    # Formation : les points arrivent d'un nuage dispersé, à des vitesses différentes.
    start = rng.normal(size=(COUNT, 3))
    start = start / np.linalg.norm(start, axis=1, keepdims=True) * rng.uniform(1.6, 2.6, size=(COUNT, 1))
    delay = rng.uniform(0, 0.45, size=COUNT)
    tilt = -0.42
    for f in range(FORM):
        t = f / (FORM - 1)
        local = np.clip((t - delay) / (1 - delay), 0, 1)
        k = ease(local)[:, None]
        yaw = 0.6 - 0.8 * (1 - ease(t))
        pts = rot(start * (1 - k) + base * k, yaw, tilt)
        render(pts, accent, np.clip(local * 1.6, 0, 1)).save(out / f"forme-{f:02d}.png")
    for f in range(LOOP):
        yaw = 0.6 + 2 * np.pi * f / LOOP
        render(rot(base, yaw, tilt), accent, np.ones(COUNT)).save(out / f"orbe-{f:02d}.png")

    # Champ du mot de passe (disque chiffré) : cadre Orbe et point de saisie.
    w, h = 360, 48
    box = Image.new("RGBA", (w * 2, h * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(box)
    d.rounded_rectangle((1, 1, w * 2 - 2, h * 2 - 2), radius=12, fill=SURFACE + (255,), outline=ACCENT + (255,), width=3)
    box.resize((w, h), Image.LANCZOS).save(out / "champ.png")
    dot = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    ImageDraw.Draw(dot).ellipse((2, 2, 21, 21), fill=TEXT + (255,))
    dot.resize((12, 12), Image.LANCZOS).save(out / "point.png")
    print(f"Plymouth orbe : {FORM} + {LOOP} images")


if __name__ == "__main__":
    main()
