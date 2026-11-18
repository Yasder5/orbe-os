#!/usr/bin/env python3
"""Capture de la fenêtre QEMU sur un écran X (utilisé par test.sh --xvfb).
Usage : xshot.py DISPLAY FICHIER.png
La fenêtre est repérée avec xwininfo (titre « QEMU (... »), la plus grande l'emporte."""
import re
import subprocess
import sys

from PIL import ImageGrab

display, out = sys.argv[1], sys.argv[2]
tree = subprocess.run(["xwininfo", "-root", "-tree", "-display", display],
                      capture_output=True, text=True, check=True).stdout
best = None
for line in tree.splitlines():
    if '"QEMU (' not in line:
        continue
    m = re.search(r"(\d+)x(\d+)\+(-?\d+)\+(-?\d+)\s+\+(-?\d+)\+(-?\d+)\s*$", line)
    if m:
        w, h, x, y = int(m[1]), int(m[2]), int(m[5]), int(m[6])
        if best is None or w * h > best[0] * best[1]:
            best = (w, h, x, y)
if best is None:
    ImageGrab.grab(xdisplay=display).save(out)
else:
    w, h, x, y = best
    ImageGrab.grab(bbox=(x, y, x + w, y + h), xdisplay=display).save(out)
