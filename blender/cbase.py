"""Shared spec registry + small decorative helpers used by the chars_*.py spec files."""
import math

import numpy as np
from mathutils import Vector as V

import bm_lib as L
from bm_arch import chain, head, spike  # noqa: F401  (re-exported for spec files)

S = L.srgb
SPECS = {}


def legs6(B, z, bw, ys, color, reach=.5):
    """insect/crab legs on both sides at the given y positions"""
    for sx in (1, -1):
        for y in ys:
            a = (sx * bw * .4, y, z)
            b = (sx * (bw * .4 + reach * .55), y, z + .12)
            c = (sx * (bw * .4 + reach), y, .03)
            B.seg(a, b, .09, .09, color)
            B.seg(b, c, .08, .08, color, t1=.5)


def latte(B, A, p, c, size=(.5, .5, .24), cup="main", foam="belly", art="sub"):
    """coffee cup with a spiral latte-art top"""
    nm = f"latte{len(A.regions)}"
    r = A.region(nm, 128, 128)
    r.fill(S(*p[foam]))
    r.spiral(64, 64, 20, 7, 60, S(*p[art]))
    B.box(c, size, cup, faces={"+z": nm}, top=(1.12, 1.12), bot=(.8, .8))


def disc(A, p, name, n, colors):
    """concentric rings (target / shield) painted into a square region"""
    r = A.region(name, n, n)
    r.fill(S(*p[colors[0]]))
    for k, col in enumerate(colors[1:], 1):
        rad = n * .5 * (1 - k / len(colors))
        r.ellipse(n / 2, n / 2, rad, rad, S(*p[col]))
    return name


def radiation(A, p, name, n=96, bg="dark", fg="accent"):
    """radioactive trefoil symbol region"""
    r = A.region(name, n, n)
    r.fill(S(*p[bg]))
    dx, dy = r.X - n / 2, r.Y - n / 2
    rad, th = np.hypot(dx, dy), np.degrees(np.arctan2(dy, dx))
    sector = (np.floor((th + 30) / 60) % 2) == 0
    r.fill(S(*p[fg]), (rad < n * .44) & (rad > n * .1) & sector)
    r.fill(S(*p[fg]), (rad < n * .08))
    return name


def chest_disc(B, A, p, c, name, n=96, size=.3, dz=-.25, bg="dark", fg="accent", kind="rad"):
    """round plate on a biped's chest (radioactive symbol or rings)"""
    if kind == "rad":
        radiation(A, p, name, n, bg, fg)
    else:
        disc(A, p, name, n, [bg, fg, bg, fg])
    sh = c["sh"]
    B.box((sh.x, sh.y - c["td"] / 2 - .03, sh.z + dz), (size, .06, size), "dark", faces={"-y": name})


def skirt(B, z, r, h, color, layers=2, top=.5):
    for i in range(layers):
        B.box((0, 0, z + i * .05), (r * (1 - .08 * i), r * (1 - .08 * i), h), color, top=(top, top), bot=(1, 1))


def hairband(B, hc, hw, hh, color, back=.12):
    """cap of hair over the top/back of a head"""
    B.box(hc + V((0, back / 2, hh * .12)), (hw + .04, .5 + back, hh * .85), color)
