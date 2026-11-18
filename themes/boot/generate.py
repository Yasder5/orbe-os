#!/usr/bin/env python3
"""Génère les visuels de démarrage Orbe : fond GRUB, cadres, icônes et fond syslinux.

Usage : python3 themes/boot/generate.py   (depuis la racine du dépôt, demande Pillow et numpy)
Les rendus sont écrits dans archiso/grub/themes/orbe/ et archiso/syslinux/splash.png.
Tout est dessiné ici : aucune image externe.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
GRUB = ROOT / "archiso/grub/themes/orbe"
SYSLINUX = ROOT / "archiso/syslinux"

# Jetons Orbe (docs/PROMPT.md, section 1).
BG = (10, 10, 10)
SURFACE = (18, 18, 18)
SURFACE_2 = (26, 26, 25)
LINE = (38, 38, 36)
TEXT = (245, 245, 240)
MUTED = (143, 143, 138)
ACCENT = (211, 253, 80)
ACCENT_HOVER = (225, 255, 128)
DANGER = (255, 107, 90)


def fibonacci_sphere(n):
    i = np.arange(n) + 0.5
    phi = np.arccos(1 - 2 * i / n)
    theta = np.pi * (1 + 5 ** 0.5) * i
    return np.stack([np.cos(theta) * np.sin(phi), np.sin(theta) * np.sin(phi), np.cos(phi)], axis=1)


def rotate(points, yaw, tilt):
    cy, sy, ct, st = np.cos(yaw), np.sin(yaw), np.cos(tilt), np.sin(tilt)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rx = np.array([[1, 0, 0], [0, ct, -st], [0, st, ct]])
    return points @ ry.T @ rx.T


def draw_orb(size, cx, cy, radius, count, dot, accent_ratio=0.1, boost=1.0, seed=7, scale=3):
    """Orbe de particules, dans le style d'Orbe Launcher (orb.webp) : sphère aérée de petits
    points blanc cassé translucides, dont environ 10 % sont des points citron plus gros.
    L'arrière de la sphère est plus discret que l'avant."""
    w, h = size
    layer = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = np.random.default_rng(seed)
    pts = rotate(fibonacci_sphere(count), yaw=0.6, tilt=-0.42)
    # Léger désordre pour éviter l'effet de grille régulière.
    pts += rng.normal(scale=0.018, size=pts.shape)
    is_accent = rng.random(count) < accent_ratio
    order = np.argsort(pts[:, 2])
    for idx in order:
        x, y, z = pts[idx]
        depth = min(max((z + 1) / 2, 0.0), 1.0)
        if is_accent[idx]:
            color, r = ACCENT, dot * 2.0 * (0.55 + 0.45 * depth)
            a = 0.32 + 0.6 * depth
        else:
            color, r = TEXT, dot * (0.7 + 0.3 * depth)
            a = 0.06 + 0.24 * depth
        a = int(255 * min(1.0, a * boost))
        px, py = (cx + x * radius) * scale, (cy + y * radius) * scale
        r *= scale
        d.ellipse([px - r, py - r, px + r, py + r], fill=color + (a,))
    return layer.resize((w, h), Image.LANCZOS)


def radial_halo(size, cx, cy, radius, alpha):
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.hypot(xx - cx, yy - cy) / radius
    a = np.clip(1 - dist, 0, 1) ** 2.2 * alpha
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    arr[..., :3] = ACCENT
    arr[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def background(size, cx, cy, radius, count, dot):
    img = Image.new("RGBA", size, BG + (255,))
    # Halo très discret : le noir reste profond.
    img.alpha_composite(radial_halo(size, cx, cy, radius * 1.6, 0.05))
    img.alpha_composite(draw_orb(size, cx, cy, radius, count, dot))
    return img.convert("RGB")


def rounded_box(size, radius, fill, outline=None, width=1, glow=0, scale=4):
    """Boîte arrondie, avec halo optionnel autour (anneau de focus Orbe)."""
    w, h = size
    img = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = glow * scale
    box = [m, m, w * scale - m - 1, h * scale - m - 1]
    if glow:
        halo = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(halo).rounded_rectangle(box, radius * scale, fill=ACCENT + (90,))
        img.alpha_composite(halo.filter(ImageFilter.GaussianBlur(glow * scale / 2)))
    d.rounded_rectangle(box, radius * scale, fill=fill + (255,),
                        outline=(outline + (255,)) if outline else None, width=width * scale)
    return img.resize(size, Image.LANCZOS)


def nine_slice(img, border, prefix, outdir):
    """Découpe une boîte en 9 morceaux pour les styles de GRUB (prefix_nw.png, ...)."""
    w, h = img.size
    b = border
    parts = {
        "nw": (0, 0, b, b), "n": (b, 0, w - b, b), "ne": (w - b, 0, w, b),
        "w": (0, b, b, h - b), "c": (b, b, w - b, h - b), "e": (w - b, b, w, h - b),
        "sw": (0, h - b, b, h), "s": (b, h - b, w - b, h), "se": (w - b, h - b, w, h),
    }
    for name, box in parts.items():
        img.crop(box).save(outdir / f"{prefix}_{name}.png")


def icon(kind, color, size=24, scale=8):
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    lw = int(1.6 * scale)
    c = color + (255,)
    if kind == "orbe":
        return draw_orb((size, size), size / 2, size / 2, size * 0.4, 46, 0.75,
                        accent_ratio=0.3, boost=2.6, seed=3, scale=scale)
    if kind == "memtest86":
        m = s * 0.24
        d.rounded_rectangle([m, m, s - m, s - m], 2 * scale, outline=c, width=lw)
        for k in range(3):
            p = m + (s - 2 * m) * (k + 1) / 4
            d.line([p, m * 0.45, p, m], fill=c, width=lw)
            d.line([p, s - m, p, s - m * 0.45], fill=c, width=lw)
            d.line([m * 0.45, p, m, p], fill=c, width=lw)
            d.line([s - m, p, s - m * 0.45, p], fill=c, width=lw)
    elif kind == "efi":
        for k, (y, knob) in enumerate(((0.32, 0.36), (0.68, 0.64))):
            d.line([s * 0.18, s * y, s * 0.82, s * y], fill=c, width=lw)
            r = s * 0.085
            d.ellipse([s * knob - r, s * y - r, s * knob + r, s * y + r], fill=(0, 0, 0, 0), outline=c, width=lw)
            d.ellipse([s * knob - r + lw / 2, s * y - r + lw / 2, s * knob + r - lw / 2, s * y + r - lw / 2], fill=BG + (255,))
    elif kind == "windows":
        # Autre système (Windows, trouvé par os-prober) : quatre carreaux au trait.
        m, g = s * 0.2, s * 0.06
        h = (s - 2 * m - g) / 2
        for x in (m, m + h + g):
            for y in (m, m + h + g):
                d.rounded_rectangle([x, y, x + h, y + h], 1.5 * scale, outline=c, width=lw)
    elif kind == "shutdown":
        m = s * 0.2
        d.arc([m, m, s - m, s - m], start=-50, end=230, fill=c, width=lw)
        d.line([s / 2, s * 0.14, s / 2, s * 0.48], fill=c, width=lw)
    elif kind == "reboot":
        m = s * 0.2
        d.arc([m, m, s - m, s - m], start=-20, end=270, fill=c, width=lw)
        ax, ay = s / 2 + (s / 2 - m) * np.cos(np.radians(-20)), s / 2 + (s / 2 - m) * np.sin(np.radians(-20))
        a = s * 0.12
        d.polygon([(ax - a, ay - a * 0.2), (ax + a, ay - a * 0.2), (ax, ay + a)], fill=c)
    return img.resize((size, size), Image.LANCZOS)


def main():
    GRUB.mkdir(parents=True, exist_ok=True)
    (GRUB / "icons").mkdir(exist_ok=True)

    # Fond GRUB 1920x1080 : menu à gauche, orbe à droite.
    background((1920, 1080), 1420, 540, 430, 720, 2.6).save(GRUB / "background.png", optimize=True)

    # Panneau du menu : surface, bordure line, rayon 8 px.
    nine_slice(rounded_box((48, 48), 8, SURFACE, LINE, 1), 12, "menu", GRUB)
    # Élément choisi : surface-2, anneau accent de 2 px, rayon 4 px, halo court.
    # Bordure fine : GRUB décale le texte de l'élément choisi de l'épaisseur de ce cadre.
    nine_slice(rounded_box((32, 32), 4, SURFACE_2, ACCENT, 2, glow=2), 6, "select", GRUB)
    # Console GRUB (touche C ou E) : même panneau.
    nine_slice(rounded_box((48, 48), 8, SURFACE, LINE, 1), 12, "terminal", GRUB)

    for kind, color in (("orbe", ACCENT), ("memtest86", TEXT), ("efi", TEXT), ("windows", TEXT),
                        ("shutdown", DANGER), ("reboot", TEXT)):
        icon(kind, color).save(GRUB / "icons" / f"{kind}.png")

    # Fond syslinux 640x480 (BIOS) : orbe en haut à droite, le menu occupe la gauche.
    background((640, 480), 486, 180, 128, 420, 1.15).save(SYSLINUX / "splash.png", optimize=True)


if __name__ == "__main__":
    main()
