#!/usr/bin/env python3
"""Adds a caption under every cell of a rendered grid frame.

usage: label_grid.py IN.png OUT.png COLS CELL_PX LABEL...
"""
import sys

from PIL import Image, ImageDraw, ImageFont

src, dst, cols, cell = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
labels = sys.argv[5:]
img = Image.open(src).convert("RGB")
draw = ImageDraw.Draw(img)
font = ImageFont.load_default(size=22)
for i, label in enumerate(labels):
    col, row = i % cols, i // cols
    x = col * cell + cell / 2
    y = row * cell + cell - 28
    draw.text((x, y), label, fill=(150, 150, 155), font=font, anchor="mm")
img.save(dst, optimize=True)
