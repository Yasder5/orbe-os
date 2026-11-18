#!/usr/bin/env python3
"""Logo Orbe : orbe de particules en SVG (vectoriel) et en PNG de 16 à 512 px.

Usage : python3 generate.py SORTIE   (demande Pillow et numpy)
Même construction que les visuels de démarrage : sphère de Fibonacci inclinée, points blanc
cassé et environ un point sur sept en citron, plus gros. Les petites tailles ont moins de points.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

TEXT = (245, 245, 240)
ACCENT = (211, 253, 80)


def points(n):
    i = np.arange(n) + 0.5
    phi = np.arccos(1 - 2 * i / n)
    theta = np.pi * (1 + 5 ** 0.5) * i
    p = np.stack([np.cos(theta) * np.sin(phi), np.sin(theta) * np.sin(phi), np.cos(phi)], axis=1)
    yaw, tilt = 0.6, -0.42
    cy, sy, ct, st = np.cos(yaw), np.sin(yaw), np.cos(tilt), np.sin(tilt)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rx = np.array([[1, 0, 0], [0, ct, -st], [0, st, ct]])
    p = p @ ry.T @ rx.T
    order = np.argsort(p[:, 2])
    return p[order], (np.arange(n) % 7 == 0)[order]


def svg(n=140):
    pts, accent = points(n)
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">',
           '<title>Orbe OS</title>']
    for (x, y, z), a in zip(pts, accent):
        depth = (z + 1) / 2
        cx, cy = 128 + x * 104, 128 + y * 104
        if a:
            out.append(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{5.2 * (0.6 + 0.4 * depth):.2f}" fill="#d3fd50" opacity="{0.35 + 0.65 * depth:.2f}"/>')
        else:
            out.append(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{3.0 * (0.6 + 0.4 * depth):.2f}" fill="#f5f5f0" opacity="{0.2 + 0.7 * depth:.2f}"/>')
    out.append("</svg>")
    return "\n".join(out) + "\n"


def png(size):
    n = 26 if size <= 24 else 46 if size <= 48 else 110 if size <= 128 else 200
    ss = 4
    w = size * ss
    img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    glow = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    d, g = ImageDraw.Draw(img), ImageDraw.Draw(glow)
    pts, accent = points(n)
    base = w / (14 if size <= 24 else 24 if size <= 48 else 64 if size <= 128 else 96)
    for (x, y, z), a in zip(pts, accent):
        depth = (z + 1) / 2
        cx, cy = w / 2 + x * w * 0.4, w / 2 + y * w * 0.4
        if a:
            r = base * 1.7 * (0.6 + 0.4 * depth)
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=ACCENT + (int(255 * (0.4 + 0.6 * depth)),))
            g.ellipse((cx - 3 * r, cy - 3 * r, cx + 3 * r, cy + 3 * r), fill=ACCENT + (26,))
        else:
            r = base * (0.6 + 0.4 * depth)
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=TEXT + (int(255 * (0.3 + 0.7 * depth)),))
    glow = glow.filter(ImageFilter.GaussianBlur(w / 40))
    glow.alpha_composite(img)
    return glow.resize((size, size), Image.LANCZOS)


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    (out / "orbe.svg").write_text(svg(), encoding="utf-8")
    for size in (16, 22, 24, 32, 48, 64, 128, 256, 512):
        png(size).save(out / f"orbe-{size}.png")
    print("Logo Orbe : SVG et 9 tailles PNG")


if __name__ == "__main__":
    main()
