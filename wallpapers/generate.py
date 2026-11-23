#!/usr/bin/env python3
"""Fonds d'écran Orbe, générés ici (aucune image externe) en 3840x2160.

Usage : python3 wallpapers/generate.py   (depuis la racine du dépôt, demande Pillow et numpy)
Rendus écrits dans wallpapers/rendus/, installés par le paquet orbe-wallpapers dans
/usr/share/backgrounds/orbe/. Le fond animé « Orbe vivant » est dessiné en direct par le shell.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "themes/boot"))
from generate import BG, LINE, ACCENT, TEXT, draw_orb, radial_halo  # noqa: E402

OUT = ROOT / "wallpapers/rendus"
W, H = 3840, 2160


def base():
    return Image.new("RGBA", (W, H), BG + (255,))


def vignette(img, strength=0.35):
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.hypot((xx - W / 2) / (W / 2), (yy - H / 2) / (H / 2)) / np.sqrt(2)
    a = (np.clip(d, 0, 1) ** 2 * strength * 255).astype(np.uint8)
    layer = np.zeros((H, W, 4), dtype=np.uint8)
    layer[..., 3] = a
    img.alpha_composite(Image.fromarray(layer, "RGBA"))
    return img


def orbe():
    """L'orbe à droite, comme le menu de démarrage."""
    img = base()
    img.alpha_composite(radial_halo((W, H), 2840, 1080, 860 * 1.6, 0.05))
    img.alpha_composite(draw_orb((W, H), 2840, 1080, 860, 1100, 4.6, scale=2))
    return vignette(img)


def orbe_centre():
    """L'orbe au centre, plus petit : pour les écrans larges et les bureaux chargés."""
    img = base()
    img.alpha_composite(radial_halo((W, H), W / 2, H / 2, 620 * 1.7, 0.06))
    img.alpha_composite(draw_orb((W, H), W / 2, H / 2, 620, 900, 4.0, seed=11, scale=2))
    return vignette(img, 0.45)


def grille():
    """Grille fine de points, halo citron discret en bas à gauche."""
    img = base()
    img.alpha_composite(radial_halo((W, H), 520, 1880, 1700, 0.07))
    dots = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(dots)
    step = 64
    for y in range(step // 2, H, step):
        for x in range(step // 2, W, step):
            dist = np.hypot(x - 520, y - 1880) / 2600
            a = int(255 * max(0.05, 0.32 - 0.26 * dist))
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=TEXT + (a,))
    img.alpha_composite(dots)
    # Quelques points de la grille passent à l'accent, comme les particules de l'orbe.
    rng = np.random.default_rng(5)
    accent = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    da = ImageDraw.Draw(accent)
    for _ in range(26):
        x = step // 2 + step * rng.integers(0, W // step)
        y = step // 2 + step * rng.integers(0, H // step)
        if np.hypot(x - 520, y - 1880) < 2400:
            da.ellipse([x - 4, y - 4, x + 4, y + 4], fill=ACCENT + (200,))
    img.alpha_composite(accent)
    return vignette(img, 0.5)


def halo():
    """Noir profond et un grand halo citron très doux : le plus sobre."""
    img = base()
    img.alpha_composite(radial_halo((W, H), W * 0.62, H * 1.05, 2600, 0.14))
    img.alpha_composite(radial_halo((W, H), W * 0.62, H * 1.05, 900, 0.10))
    # Ligne d'horizon fine, en line.
    line = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(line).line([(0, int(H * 0.78)), (W, int(H * 0.78))], fill=LINE + (180,), width=2)
    img.alpha_composite(line.filter(ImageFilter.GaussianBlur(1)))
    return vignette(img, 0.4)


def constellation(seed, sides, cx=0.68, cy=0.48, size=0.30, twist=0.0):
    """Fond « constellation », tiré des fausses jaquettes du mode jeu : une forme géométrique au
    trait citron (polygone irrégulier, doublé d'un trait plus fin), poussière d'étoiles blanc
    cassé et citron, halos citron très doux. Composition à droite : la barre et les fenêtres
    gardent la gauche lisible."""
    rnd = np.random.default_rng(seed)
    img = base()
    sc = 4  # halos calculés en quart de définition puis agrandis
    glow = Image.new("RGBA", (W // sc, H // sc), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    for _ in range(10):
        x = rnd.normal(cx, 0.16) * W / sc
        y = rnd.normal(cy, 0.2) * H / sc
        r = rnd.uniform(60, 220)
        g.ellipse([x - r, y - r, x + r, y + r], fill=ACCENT + (int(rnd.uniform(10, 26)),))
    glow = glow.filter(ImageFilter.GaussianBlur(70)).resize((W, H), Image.BICUBIC)
    img.alpha_composite(glow)

    d = ImageDraw.Draw(img)
    # Poussière d'étoiles, plus dense autour de la forme.
    for _ in range(1400):
        if rnd.random() < 0.6:
            x, y = rnd.normal(cx, 0.2) * W, rnd.normal(cy, 0.26) * H
        else:
            x, y = rnd.uniform(0, W), rnd.uniform(0, H)
        r = rnd.choice([1.5, 2, 2.5, 3, 4.5], p=[0.35, 0.3, 0.2, 0.1, 0.05])
        accent = rnd.random() < 0.18
        col = (ACCENT if accent else TEXT) + (int(rnd.uniform(70, 230)),)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)

    # Forme : sommets sur un cercle, rayon irrégulier, tournée de « twist ».
    R = size * H
    pts = []
    for i in range(sides):
        a = twist + i * 2 * np.pi / sides
        rr = R * rnd.uniform(0.65, 1.05)
        pts.append((cx * W + np.cos(a) * rr, cy * H + np.sin(a) * rr))
    line = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line)
    ld.line(pts + [pts[0]], fill=ACCENT + (255,), width=7, joint="curve")
    # Second trait, décalé et plus fin, comme sur les jaquettes.
    off = [(x + R * 0.06, y + R * 0.05) for x, y in pts[1:] + pts[:1]]
    ld.line(off[: max(2, sides // 2 + 1)], fill=ACCENT + (140,), width=3, joint="curve")
    halo_line = line.resize((W // sc, H // sc)).filter(ImageFilter.GaussianBlur(10)).resize((W, H), Image.BICUBIC)
    img.alpha_composite(halo_line)
    img.alpha_composite(line)
    # Sommets marqués d'un point citron.
    for x, y in pts:
        d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=ACCENT + (255,))
    return vignette(img, 0.45)


CONSTELLATIONS = (
    ("nebuleuse", dict(seed=10, sides=6, twist=0.3)),
    ("circuit", dict(seed=20, sides=4, twist=0.9, size=0.34)),
    ("foret", dict(seed=30, sides=3, twist=-0.4, size=0.36)),
    ("orbital", dict(seed=40, sides=5, twist=1.2)),
    ("atlas", dict(seed=80, sides=7, twist=0.1, cy=0.52)),
)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    makers = [("orbe", orbe), ("orbe-centre", orbe_centre), ("grille", grille), ("halo", halo)]
    makers += [(name, (lambda kw=kw: constellation(**kw))) for name, kw in CONSTELLATIONS]
    only = set(sys.argv[1:])
    for name, make in makers:
        if only and name not in only:
            continue
        path = OUT / f"{name}.png"
        make().convert("RGB").save(path, optimize=True)
        print(f"{path.relative_to(ROOT)} : {path.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    main()
