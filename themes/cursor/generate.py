#!/usr/bin/env python3
"""Curseur Orbe : formes noires, contour blanc cassé, point citron.

Usage : python3 generate.py SORTIE
Écrit dans SORTIE/png les images (tailles 24, 32, 48, 64) et dans SORTIE/cfg les fichiers de
xcursorgen. build.sh (paquet orbe-cursor) les assemble ensuite en thème xcursor puis hyprcursor.
Tout est dessiné ici, sur une grille de 32 unités : aucune image externe. Demande Pillow.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

FILL = (10, 10, 10, 255)
LINE = (245, 245, 240, 255)
ACCENT = (211, 253, 80, 255)
DANGER = (255, 107, 90, 255)
SIZES = (24, 32, 48, 64)
SS = 8  # suréchantillonnage


class Canvas:
    """Dessin en unités de 32 : forme pleine (masque), puis contour par dilatation."""

    def __init__(self, size):
        self.size = size
        self.px = size * SS
        self.k = self.px / 32
        self.mask = Image.new("L", (self.px, self.px), 0)
        self.d = ImageDraw.Draw(self.mask)
        self.marks = []  # (forme, couleur, géométrie) dessinées par-dessus

    def s(self, pts):
        return [(x * self.k, y * self.k) for x, y in pts]

    def poly(self, pts):
        self.d.polygon(self.s(pts), fill=255)

    def rrect(self, x0, y0, x1, y1, r):
        self.d.rounded_rectangle(self.s([(x0, y0), (x1, y1)]), radius=r * self.k, fill=255)

    def circle(self, cx, cy, r, mask=None, fill=255):
        (mask or self.d).ellipse(self.s([(cx - r, cy - r), (cx + r, cy + r)]), fill=fill)

    def line(self, pts, w):
        self.d.line(self.s(pts), fill=255, width=max(1, round(w * self.k)), joint="curve")
        for x, y in (pts[0], pts[-1]):
            self.circle(x, y, w / 2)

    def mark(self, kind, color, *geom):
        self.marks.append((kind, color, geom))

    def render(self, outline=1.6):
        rad = max(1, round(outline * self.k))
        grown = self.mask.filter(ImageFilter.MaxFilter(2 * rad + 1))
        img = Image.new("RGBA", (self.px, self.px), (0, 0, 0, 0))
        img.paste(Image.new("RGBA", img.size, LINE), (0, 0), grown)
        img.paste(Image.new("RGBA", img.size, FILL), (0, 0), self.mask)
        d = ImageDraw.Draw(img)
        for kind, color, geom in self.marks:
            if kind == "dot":
                cx, cy, r = geom
                d.ellipse(self.s([(cx - r, cy - r), (cx + r, cy + r)]), fill=color)
            elif kind == "arc":
                cx, cy, r, a0, a1, w = geom
                d.arc(self.s([(cx - r, cy - r), (cx + r, cy + r)]), a0, a1, fill=color, width=max(1, round(w * self.k)))
            elif kind == "line":
                pts, w = geom
                d.line(self.s(pts), fill=color, width=max(1, round(w * self.k)))
                for x, y in (pts[0], pts[-1]):
                    d.ellipse(self.s([(x - w / 2, y - w / 2), (x + w / 2, y + w / 2)]), fill=color)
        # Ombre douce sous la forme, pour la lisibilité sur fond clair comme sombre.
        shadow = grown.filter(ImageFilter.GaussianBlur(1.2 * self.k))
        shadow = ImageChops.offset(shadow, 0, round(0.8 * self.k)).point(lambda v: v * 0.35)
        out = Image.new("RGBA", img.size, (0, 0, 0, 0))
        out.paste(Image.new("RGBA", img.size, (0, 0, 0, 255)), (0, 0), shadow)
        out.alpha_composite(img)
        return out.resize((self.size, self.size), Image.LANCZOS)


# Formes : chaque fonction dessine sur c et renvoie le point actif (unités de 32).
def arrow(c, dot=True):
    c.poly([(4, 3), (4, 25.5), (9.6, 20.4), (13.4, 28.6), (17.2, 26.9), (13.5, 18.8), (21, 18.6)])
    if dot:
        c.mark("dot", ACCENT, 7.2, 13.2, 1.7)
    return (4, 3)


def hand(c):
    c.rrect(10.6, 2.6, 15, 18, 2.2)                     # index tendu
    c.rrect(15, 10.6, 18.6, 18, 1.8)                    # majeur replié
    c.rrect(18.6, 11.8, 22.2, 18.5, 1.8)                # annulaire
    c.rrect(22.2, 13.4, 25.4, 19.5, 1.6)                # auriculaire
    c.rrect(8.4, 14.5, 25.4, 28.5, 4.5)                 # paume
    c.poly([(9.4, 18), (5.2, 14.4), (3.6, 16.3), (8.6, 23.5)])  # pouce
    c.mark("dot", ACCENT, 12.8, 5.6, 1.5)
    return (12.8, 3)


def open_hand(c):
    for x0, y0 in ((8.4, 5), (12.2, 3.2), (16, 4), (19.8, 6.6)):
        c.rrect(x0, y0, x0 + 3.4, 18, 1.7)
    c.rrect(8.4, 13.5, 24, 28.5, 4.5)
    c.poly([(9.4, 18), (4.4, 13.6), (2.8, 15.6), (8.6, 23.5)])
    c.mark("dot", ACCENT, 16.2, 21, 1.5)
    return (16, 14)


def closed_hand(c):
    c.rrect(8.4, 10.5, 24, 27.5, 4.5)
    for x in (9.8, 13.4, 17, 20.6):
        c.circle(x + 1.6, 11.6, 1.9)
    c.poly([(9.4, 16), (5.6, 14.5), (4.4, 16.6), (8.6, 22)])
    c.mark("dot", ACCENT, 16.2, 19.5, 1.5)
    return (16, 16)


def ibeam(c):
    c.rrect(14.9, 5.5, 17.1, 26.5, 0.6)
    c.rrect(11.5, 4.2, 20.5, 6.4, 1)
    c.rrect(11.5, 25.6, 20.5, 27.8, 1)
    return (16, 16)


def crosshair(c):
    for pts in (((16, 3.5), (16, 12.5)), ((16, 19.5), (16, 28.5)), ((3.5, 16), (12.5, 16)), ((19.5, 16), (28.5, 16))):
        c.line(pts, 2)
    c.mark("dot", ACCENT, 16, 16, 1.8)
    return (16, 16)


def spinner(c, frame, frames, cx=16, cy=16, r=9):
    c.circle(cx, cy, r + 2.4)
    a = 360 * frame / frames
    c.mark("arc", (58, 58, 55, 255), cx, cy, r, 0, 360, 2.6)
    c.mark("arc", ACCENT, cx, cy, r, a - 90, a + 20, 2.6)
    return (cx, cy)


def progress(c, frame, frames):
    arrow(c, dot=False)
    spinner(c, frame, frames, 22.4, 22.4, 4.4)
    return (4, 3)


def not_allowed(c):
    c.circle(16, 16, 11.5)
    c.mark("arc", DANGER, 16, 16, 8.4, 0, 360, 2.6)
    c.mark("line", DANGER, ((10.2, 10.2), (21.8, 21.8)), 2.6)
    return (16, 16)


def double_arrow(c, angle):
    """Flèche à deux pointes, tournée de angle degrés (0 = horizontale)."""
    a = math.radians(angle)
    ca, sa = math.cos(a), math.sin(a)
    shape = [(-12, 0), (-6, -6), (-6, -2.2), (6, -2.2), (6, -6), (12, 0), (6, 6), (6, 2.2), (-6, 2.2), (-6, 6)]
    c.poly([(16 + x * ca - y * sa, 16 + x * sa + y * ca) for x, y in shape])
    c.mark("dot", ACCENT, 16, 16, 1.4)
    return (16, 16)


def move(c):
    for angle in (0, 90):
        a = math.radians(angle)
        ca, sa = math.cos(a), math.sin(a)
        shape = [(-12.5, 0), (-7.5, -5), (-7.5, -1.8), (7.5, -1.8), (7.5, -5), (12.5, 0), (7.5, 5), (7.5, 1.8), (-7.5, 1.8), (-7.5, 5)]
        c.poly([(16 + x * ca - y * sa, 16 + x * sa + y * ca) for x, y in shape])
    c.mark("dot", ACCENT, 16, 16, 1.6)
    return (16, 16)


# Nom principal : (dessin, animé). Les alias pointent vers ces fichiers.
SHAPES = {
    "default": (arrow, False),
    "pointer": (hand, False),
    "grab": (open_hand, False),
    "grabbing": (closed_hand, False),
    "text": (ibeam, False),
    "crosshair": (crosshair, False),
    "wait": (spinner, True),
    "progress": (progress, True),
    "not-allowed": (not_allowed, False),
    "move": (move, False),
    "ew-resize": (lambda c: double_arrow(c, 0), False),
    "ns-resize": (lambda c: double_arrow(c, 90), False),
    "nwse-resize": (lambda c: double_arrow(c, 45), False),
    "nesw-resize": (lambda c: double_arrow(c, -45), False),
}

ALIASES = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "context-menu", "help", "question_arrow",
                "whats_this", "copy", "alias", "dnd-copy", "dnd-link", "dnd-move", "dnd-none", "dnd-ask",
                "zoom-in", "zoom-out", "pencil", "right_ptr", "center_ptr", "x-cursor", "X_cursor", "draft"],
    "pointer": ["hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822"],
    "grab": ["openhand", "fleur-grab", "5aca4d189052212118709018842178c0"],
    "grabbing": ["closedhand", "dnd-grab", "208530c400c041818281048008011002"],
    "text": ["xterm", "ibeam", "vertical-text"],
    "crosshair": ["cross", "tcross", "cell", "plus", "color-picker", "target"],
    "wait": ["watch"],
    "progress": ["left_ptr_watch", "half-busy", "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd"],
    "not-allowed": ["crossed_circle", "no-drop", "forbidden", "circle", "03b6e0fcb3499374a867c041f52298f0"],
    "move": ["fleur", "all-scroll", "size_all", "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f"],
    "ew-resize": ["e-resize", "w-resize", "col-resize", "sb_h_double_arrow", "h_double_arrow", "size_hor",
                  "split_h", "left_side", "right_side", "14fef782d02440884392942c11205230", "028006030e0e7ebffc7f7070c0600140"],
    "ns-resize": ["n-resize", "s-resize", "row-resize", "sb_v_double_arrow", "v_double_arrow", "size_ver",
                  "split_v", "top_side", "bottom_side", "2870a09082c103050810ffdffffe0204", "00008160000006810000408080010102"],
    "nwse-resize": ["nw-resize", "se-resize", "size_fdiag", "top_left_corner", "bottom_right_corner", "bd_double_arrow",
                    "c7088f0f3e6c8088236ef8e1e3e70000"],
    "nesw-resize": ["ne-resize", "sw-resize", "size_bdiag", "top_right_corner", "bottom_left_corner", "fd_double_arrow",
                    "fcf1c3c7cd4491d801f1e1c78f100000"],
}

FRAMES = 12
DELAY = 60  # ms par image


def main():
    out = Path(sys.argv[1])
    (out / "png").mkdir(parents=True, exist_ok=True)
    (out / "cfg").mkdir(parents=True, exist_ok=True)
    for name, (draw, animated) in SHAPES.items():
        lines = []
        for size in SIZES:
            for frame in range(FRAMES if animated else 1):
                c = Canvas(size)
                hx, hy = draw(c, frame, FRAMES) if animated else draw(c)
                png = f"{name}-{size}" + (f"-{frame:02d}" if animated else "") + ".png"
                c.render().save(out / "png" / png)
                hot = (round(hx * size / 32), round(hy * size / 32))
                lines.append(f"{size} {hot[0]} {hot[1]} {png}" + (f" {DELAY}" if animated else ""))
        (out / "cfg" / f"{name}.cfg").write_text("\n".join(lines) + "\n")
    with open(out / "aliases.txt", "w") as f:
        for target, names in ALIASES.items():
            for n in names:
                f.write(f"{n} {target}\n")
    print(f"{len(SHAPES)} curseurs, {sum(len(v) for v in ALIASES.values())} alias")


if __name__ == "__main__":
    main()
