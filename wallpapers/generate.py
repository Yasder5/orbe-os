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


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in (("orbe", orbe), ("orbe-centre", orbe_centre), ("grille", grille), ("halo", halo)):
        path = OUT / f"{name}.png"
        make().convert("RGB").save(path, optimize=True)
        print(f"{path.relative_to(ROOT)} : {path.stat().st_size // 1024} Ko")


if __name__ == "__main__":
    main()
