"""Archetype generators (quad / biped / serpent / blob / fish / custom) for Brainmon specs.

A spec is a dict (see characters.py). Colours are referenced by palette name: main, sub, belly,
accent, dark, claw, eye, white, black (+ any extra names given in spec['pal']).
All builders return an anchor dict used by wings/spines/extra.
"""
import math

from mathutils import Matrix, Vector as V

import bm_lib as L

S = L.srgb


def palette(A, s):
    p = dict(s["pal"])
    m = p["main"]
    for k, v in (("sub", m), ("belly", p.get("sub", m)), ("dark", (28, 28, 34)), ("accent", p.get("sub", m)),
                 ("eye", (30, 30, 50)), ("claw", (236, 226, 200)), ("white", (250, 250, 250)),
                 ("black", (14, 14, 18))):
        p.setdefault(k, v)
    for k, v in p.items():
        A.color(k, v)
    return p


def _euler(d):
    d = V(d).normalized()
    xr = V((1, 0, 0)) if abs(d.x) < 0.9 else V((0, 1, 0))
    y = d.cross(xr).normalized()
    x = y.cross(d)
    return tuple(math.degrees(a) for a in Matrix((x, y, d)).transposed().to_euler())


def spike(B, base, d, ln, r, color, seg=4):
    d = V(d).normalized()
    B.cone(V(base) + d * ln / 2, r, ln, color, rot=_euler(d), segments=seg)


def chain(B, start, a0, curve, n, ln, w0, w1, color, color2=None, flip=1, x=0.0, depth=1.0):
    """tapered polyline; angle from +Y(back, flip=-1: front) up toward +Z, changing by `curve` per segment"""
    q = V(start) + V((x, 0, 0))
    pts = [q]
    d = V((0, 1, 0))
    for i in range(n):
        a = math.radians(a0 + curve * i)
        d = V((0, math.cos(a) * flip, math.sin(a)))
        e = q + d * ln
        wa = w0 + (w1 - w0) * i / n
        wb = w0 + (w1 - w0) * (i + 1) / n
        B.seg(q, e, wa, wa * depth, color2 if (color2 and i % 2) else color, t0=1, t1=wb / wa)
        if i < n - 1:
            B.box(e, (wb, wb * depth, wb), color2 if (color2 and i % 2) else color)  # joint filler
        q = e
        pts.append(q)
    return pts, d


# ---------------------------------------------------------------- painting
def face(A, p, name, w, h, f):
    r = A.region(name, w, h)
    r.fill(S(*p[f.get("base", "main")]))
    if f.get("lower"):
        r.rect(0, 0, w, h * 0.3, S(*p[f["lower"]]))
    if f.get("blaze"):
        r.rect(w * 0.44, 0, w * 0.56, h * 0.8, S(*p[f["blaze"]]))
    if f.get("bricks"):
        r.bricks(12, 12, S(*p[f["bricks"]]), r.X > -1)
    dark, white, ec = S(*p["black"]), S(255, 255, 255), S(*p["eye"])
    st, ey, sep, R = f.get("eyes", "cute"), f.get("ey", 0.58), f.get("sep", 0.27), h * 0.12 * f.get("size", 1)
    if f.get("cheek"):
        for x in (sep - 0.1, 1.1 - sep):
            r.ellipse(w * x, h * (ey - 0.22), R * 0.7, R * 0.5, S(*p[f["cheek"]]))
    if st != "none":
        for i, x in enumerate((sep, 1 - sep)):
            cx, cy = w * x, h * ey
            if st == "cute":
                r.ellipse(cx, cy, R * .85, R * 1.1, dark)
                r.ellipse(cx, cy - R * .05, R * .62, R * .85, ec)
                r.ellipse(cx, cy - R * .05, R * .35, R * .55, dark)
                r.ellipse(cx - R * .22, cy + R * .4, R * .2, R * .22, white)
            elif st == "angry":
                r.ellipse(cx, cy, R * 1.1, R * .62, white)
                r.ellipse(cx, cy, R * .5, R * .5, ec)
                r.ellipse(cx, cy, R * .22, R * .3, dark)
            elif st == "slit":
                r.ellipse(cx, cy, R * 1.05, R * .7, ec)
                r.rect(cx - R * .12, cy - R * .6, cx + R * .12, cy + R * .6, dark)
            elif st == "glow":
                r.ellipse(cx, cy, R * 1.0, R * .6, ec)
            elif st == "pixel":
                r.rect(cx - R * .55, cy - R * .8, cx + R * .55, cy + R * .8, dark)
                r.rect(cx - R * .4, cy + R * .2, cx - R * .05, cy + R * .65, white)
            else:  # dot
                r.ellipse(cx, cy, R * .55, R * .6, dark)
                r.ellipse(cx - R * .12, cy + R * .2, R * .17, R * .17, white)
            if f.get("brow"):
                s_ = 1 if i == 0 else -1
                r.line((cx - s_ * R * 1.3, cy + R * 1.35), (cx + s_ * R * 1.2, cy + R * .5), R * .4, dark)
    m = f.get("mouth")
    if m == "smile":
        r.line((w * .38, h * .2), (w * .5, h * .13), 4, dark)
        r.line((w * .5, h * .13), (w * .62, h * .2), 4, dark)
    elif m == "maw":
        r.ellipse(w * .5, h * .35, w * .36, h * .28, S(*p["black"]))
        r.ellipse(w * .5, h * .32, w * .26, h * .18, S(*p.get("glow", p["accent"])))
        for k in range(7):
            xx = w * (.2 + .6 * k / 6)
            r.rect(xx - 5, h * .52, xx + 5, h * .62, S(235, 235, 225))
            r.rect(xx - 5, h * .06, xx + 5, h * .16, S(235, 235, 225))
    elif m == "open":
        r.rect(w * .32, h * .06, w * .68, h * .2, dark)
        r.rect(w * .36, h * .15, w * .42, h * .2, white)
        r.rect(w * .58, h * .15, w * .64, h * .2, white)
    for mk in f.get("marks", []):  # (shape, color, x, y, size)
        c = S(*p[mk[1]])
        if mk[0] == "spiral":
            r.spiral(w * mk[2], h * mk[3], mk[4] * 0.45, mk[4] * 0.16, mk[4], c)
        elif mk[0] == "dot":
            r.ellipse(w * mk[2], h * mk[3], mk[4], mk[4], c)
        elif mk[0] == "bar":
            r.rect(w * mk[2] - mk[4], h * mk[3] - 3, w * mk[2] + mk[4], h * mk[3] + 3, c)


def head(B, A, p, h, f, c, tag="face"):
    hw, hd, hh = h.get("size", (.5, .45, .42))
    face(A, p, tag, max(int(hw * 512), 32), max(int(hh * 512), 32), f)
    x, y, z = c
    B.box(c, (hw, hd, hh), h.get("color", "main"), faces={"-y": tag, **h.get("faces", {})}, top=h.get("top", (1, 1)))
    front = y - hd / 2
    sn = h.get("snout")
    if sn:
        sw, sd, sh = sn.get("size", (hw * .55, hd * .7, hh * .45))
        sz = z + sn.get("dz", -hh * .2)
        r = A.region(tag + "_snout", max(int(sw * 512), 24), max(int(sh * 512), 24))
        r.fill(S(*p[sn.get("color", "belly")]))
        d_ = S(*p["black"])
        if sn.get("mouth", "smile") == "smile":
            r.line((r.w * .15, r.h * .3), (r.w * .5, r.h * .18), 4, d_)
            r.line((r.w * .5, r.h * .18), (r.w * .85, r.h * .3), 4, d_)
        elif sn.get("mouth") == "fangs":
            r.rect(0, r.h * .25, r.w, r.h * .4, d_)
            for xx in (.2, .5, .8):
                r.rect(r.w * xx - 4, r.h * .2, r.w * xx + 4, r.h * .3, S(255, 255, 255))
        B.box((x, front - sd / 2 + .03, sz), (sw, sd, sh), sn.get("color", "belly"), faces={"-y": tag + "_snout"})
        if sn.get("nose", "black"):
            B.box((x, front - sd + .035, sz + sh / 2 - .03), (sw * .4, .06, .07), sn.get("nose", "black"))
    bk = h.get("beak")
    if bk:
        bw, bd, bh = bk.get("size", (.2, .25, .15))
        spike(B, (x, front + .03, z - hh * .12), (0, -1, 0), bd, bw * .7, bk.get("color", "accent"))
        if bk.get("lower"):
            spike(B, (x, front + .03, z - hh * .22), (0, -1, -.1), bd * .8, bw * .5, bk.get("lower"))
    e = h.get("ears")
    if e:
        ew, ed, eh = e.get("size", (.14, .06, .22))
        k = e.get("kind", "up")
        if k == "up":
            B.box((hw / 2 - ew / 2 - .02 + e.get("dx", 0), y + .02, z + hh / 2 + eh / 2 - .03), (ew, ed, eh),
                  e.get("color", "main"), faces={"-y": e.get("inner", "accent")}, rot=(e.get("back", 0), e.get("tilt", 12), 0),
                  top=(e.get("taper", .45),) * 2, mirror=True)
        else:  # droopy side ears
            B.box((hw / 2 + ed / 2, y + .02, z + hh * .05), (ed, ew, eh), e.get("color", "main"),
                  rot=(0, e.get("tilt", -20), 0), top=(.7, .7), mirror=True)
    hr = h.get("horns")
    if hr:
        for sx in (1, -1):
            spike(B, (x + sx * hw * hr.get("x", .3), y, z + hh / 2 - .02),
                  (sx * hr.get("out", .4), -hr.get("fwd", .1), 1), hr.get("len", .3), hr.get("r", .06), hr.get("color", "claw"))
    cr = h.get("crest")
    if cr:
        n = cr.get("n", 4)
        for i in range(n):
            t = i / max(n - 1, 1)
            spike(B, (x, y + (t - .5) * hd * .8, z + hh / 2 - .02), (0, .3 + cr.get("back", 0), 1),
                  cr.get("len", .22) * (1 - .35 * abs(t - .5) * 2), cr.get("r", .07), cr.get("color", "accent"))
    mn = h.get("mane")
    if mn:
        n = mn.get("n", 9)
        for i in range(n):
            a = math.radians(-20 + 220 * i / (n - 1))
            R0 = max(hw, hh) * .5
            spike(B, (x + math.cos(a) * R0, y + hd * .15, z + math.sin(a) * R0 * .9 - hh * .05),
                  (math.cos(a), .5, math.sin(a)), mn.get("len", .3), mn.get("r", .1), mn.get("color", "accent"))
    return z + hh / 2


def tail(B, A, p, t, start):
    if not t:
        return
    n = t.get("n", 4)
    ln = t.get("len", .7) / n
    w0 = t.get("w", .16)
    pts, d = chain(B, start, t.get("a0", 10), t.get("curve", 10), n, ln, w0, t.get("w1", w0 * .4),
                   t.get("color", "main"), t.get("color2"))
    end, tip = pts[-1], t.get("tip")
    c = t.get("tipcolor", "accent")
    if tip == "fan":
        B.box(end + V((0, .08, .12)), (t.get("fan", .45), .05, t.get("fan_h", .4)), c, top=(1.25, 1))
    elif tip == "ball":
        B.box(end + d * .05, (.2, .2, .2), c)
    elif tip == "blade":
        spike(B, end, d + V((0, 0, .5)), .3, .08, c)
    elif tip == "tuft":
        for k in (-1, 0, 1):
            spike(B, end, d + V((k * .5, 0, .6)), .28, .07, c)
    elif tip == "leaf":
        B.box(end + V((0, .12, .12)), (.3, .05, .38), c, rot=(-20, 0, 0), top=(.3, 1))


def wings(B, A, p, w, root):
    kind, col, rim = w.get("kind", "bat"), w.get("color", "accent"), w.get("rim", "sub")
    span, chord, ang = w.get("span", .9), w.get("chord", .55), w.get("angle", 30)
    rx, ry, rz = root

    def panel(sp, ch, an, dy=0.0, dz=0.0):
        nm = f"wing{len(A.regions)}"
        r = A.region(nm, max(int(sp * 300), 24), max(int(ch * 300), 24))
        r.fill(S(*p[rim]))
        r.rect(8, 8, r.w - 8, r.h - 8, S(*p[col]))
        if w.get("spots"):
            r.ellipse(r.w * .6, r.h * .5, r.h * .17, r.h * .17, S(*p[w["spots"]]))
        a = math.radians(an)
        B.box((rx + math.cos(a) * sp / 2, ry + dy, rz + math.sin(a) * sp / 2 + dz), (sp, .04, ch), col,
              faces={"-y": nm, "+y": nm}, rot=(0, -an, 0), mirror=True)

    if kind in ("bat", "butterfly", "angel"):
        panel(span, chord, ang)
        if kind == "butterfly":
            panel(span * .65, chord * .7, ang - 60, dy=.02, dz=-chord * .3)
        elif kind == "bat":
            panel(span * .7, chord * .8, ang - 35, dy=.02, dz=-chord * .25)
            for sx in (1, -1):
                B.seg((sx * rx, ry, rz), (sx * (rx + math.cos(math.radians(ang)) * span), ry,
                                           rz + math.sin(math.radians(ang)) * span + chord * .5), .06, .06, rim)
    elif kind == "feather":
        n = w.get("n", 5)
        for i in range(n):
            an = ang + (i - (n - 1) / 2) * w.get("spread", 16)
            a = math.radians(an)
            ln = span * (1 - .15 * abs(i - (n - 1) / 2))
            B.box((rx + math.cos(a) * ln / 2, ry + .02 * i, rz + math.sin(a) * ln / 2), (ln, .035, chord / n * 1.6),
                  col if i % 2 == 0 else rim, rot=(0, -an, 0), top=(1, 1), mirror=True)
    elif kind == "fin":
        panel(span, chord, ang)


def spines(B, p, sp, a, b):
    n = sp.get("n", 5)
    a, b = V(a), V(b)
    for i in range(n):
        t = i / max(n - 1, 1)
        spike(B, a + (b - a) * t, (0, sp.get("back", .35), 1), sp.get("len", .2) * (1 - .35 * abs(t - .5) * 2),
              sp.get("r", .06), sp.get("color", "accent"))


# ---------------------------------------------------------------- archetypes
def quad(B, A, p, s):
    bw, bl, bh = s.get("body", (.55, 1.0, .55))
    lh, lt = s.get("leg", .38), s.get("legw", .17)
    zc = lh + bh / 2 - .04
    top = zc + bh / 2
    B.box((0, 0, zc), (bw, bl, bh), "main", faces={"-z": "belly", **s.get("body_faces", {})}, top=s.get("body_top", (.93, .96)))
    if s.get("chest", True):
        B.box((0, -bl / 2 + .03, zc - bh * .12), (bw * .72, .06, bh * .55), "belly")
    if s.get("stripes"):
        col, n, wd = s["stripes"]
        for i in range(n):
            B.box((0, -bl * .38 + i * bl * .76 / max(n - 1, 1), zc), (bw + .02, wd, bh + .02), col)
    if s.get("saddle"):
        B.box((0, 0, top), (bw * .7, bl * .6, .05), s["saddle"])
    for pa in s.get("patches", []):  # (color, y, z_off, w, h)
        B.box((bw / 2, pa[1], zc + pa[2]), (.05, pa[3], pa[4]), pa[0], mirror=True)
    for sx in (1, -1):
        for y in (-bl / 2 + lt * .75, bl / 2 - lt * .75):
            x = sx * (bw / 2 - lt * .5)
            B.seg((x, y, lh + .04), (x, y, .09), lt, lt, "main", t0=.8, t1=1)
            if s.get("sock"):
                B.box((x, y, .17), (lt * 1.1, lt * 1.1, .15), s["sock"])
            B.box((x, y - lt * .2, .05), (lt * 1.1, lt * 1.5, .1), s.get("paw", "sub"))
            if s.get("claws"):
                for dx in (-.35, 0, .35):
                    B.box((x + dx * lt, y - lt * 1.0, .03), (.035, .05, .04), "claw")
    hs = s["head"]
    hw, hd, hh = hs.get("size", (.5, .45, .42))
    nk = s.get("neck", (0.0, .25))
    base = V((0, -bl / 2 + .08, top - .12))
    hc = V((0, -bl / 2 - hd * .2 - nk[0], top + nk[1] + hh * .35))
    B.seg(base, hc + V((0, .08, -hh * .15)), min(bw * .75, hw * .85), min(bw * .7, hd * .85), s.get("neck_color", "main"))
    head(B, A, p, hs, s.get("face", {}), hc)
    tail(B, A, p, s.get("tail"), V((0, bl / 2 - .03, zc + bh * .15)))
    return dict(wing_root=(bw / 2 * .6, -bl * .1, top - .05), spine_a=(0, bl / 2 - .05, top), spine_b=(0, -bl / 2 + .1, top + .02),
                top=top, zc=zc, bw=bw, bl=bl, bh=bh, hc=hc)


def biped(B, A, p, s):
    lt_, ls_ = s.get("legs", (.45, .42))
    lw = s.get("limb", .18) * 1.2
    pw, pd, ph = s.get("pelvis", (.5, .35, .25))
    tw, td, th = s.get("torso", (.6, .4, .55))
    lean = math.radians(s.get("lean", 0))
    fh = .09
    hip_z = s.get("hip") or (fh + ls_ + lt_)
    if not s.get("no_legs"):
        for sx in (1, -1):
            x = sx * pw * .32
            ank = V((x, .06, fh))
            knee = V((x, -s.get("knee", .1), fh + ls_))
            hip = V((x, 0, hip_z))
            B.seg(hip, knee, lw * 1.15, lw * 1.15, s.get("leg_color", "main"), t0=.85, t1=1.1)
            B.seg(knee, ank, lw, lw, s.get("shin_color", s.get("leg_color", "main")), t0=1, t1=.8)
            fl = s.get("foot", .3)
            B.box((x, ank.y - fl * .3, fh / 2), (lw * 1.3, fl, fh), s.get("foot_color", "sub"))
            if s.get("claws", True):
                for dx in (-.4, 0, .4):
                    B.box((x + dx * lw, ank.y - fl * .8, .03), (.04, .07, .05), "claw")
    B.box((0, 0, hip_z + ph / 2 - .03), (pw, pd, ph), s.get("pelvis_color", "main"))
    base = V((0, 0, hip_z + ph - .05))
    sh = base + V((0, -math.sin(lean) * th, math.cos(lean) * th))
    B.seg(base, sh, tw, td, s.get("torso_color", "main"), t0=.85, t1=1.1)
    if s.get("belly_plate", True):
        B.seg(base + V((0, -td / 2 - .01, 0)), sh + V((0, -td / 2 - .01, 0)), tw * .62, .06, "belly")
    hs = s["head"]
    hw, hd, hh = hs.get("size", (.5, .45, .42))
    nk = s.get("neck", (0.0, .1))
    hc = sh + V((0, -hd * .15 - nk[0], nk[1] + hh * .45))
    B.seg(sh + V((0, 0, -.05)), hc + V((0, .05, -hh * .3)), hw * .55, hd * .55, s.get("neck_color", "main"))
    head(B, A, p, hs, s.get("face", {}), hc)
    ar = s.get("arm", (.32, .3))
    for sx in (1, -1):
        if s.get("no_arms"):
            break
        shp = V((sx * (tw / 2 + lw * .3), sh.y + .02, sh.z - lw * .5))
        el = shp + V((sx * .04, -s.get("arm_fwd", .08), -ar[0]))
        wr = el + V((0, -s.get("fore_fwd", .08), -ar[1]))
        ac = s.get("arm_color", "main")
        B.seg(shp, el, lw, lw, ac, t0=1.15, t1=.95)
        B.seg(el, wr, lw * .95, lw * .95, s.get("fore_color", ac), t0=1, t1=1.05)
        hn = s.get("hand", lw * 1.25)
        B.box(wr + V((0, -.02, -hn * .45)), (hn, hn * 1.1, hn), s.get("hand_color", ac))
        if s.get("claws", True):
            for dx in (-.35, 0, .35):
                spike(B, wr + V((dx * hn, -.05, -hn * .8)), (0, -.5, -1), .13, .035, "claw")
        if s.get("pads"):
            B.box(shp + V((sx * .02, 0, .02)), (lw * 1.5, lw * 1.5, lw * 1.2), s["pads"])
    tail(B, A, p, s.get("tail"), V((0, pd / 2 - .02, hip_z + ph * .35)))
    return dict(wing_root=(tw * .35, sh.y + td * .4, sh.z - .05), spine_a=(0, pd / 2, hip_z + ph), spine_b=(0, sh.y + td * .45, sh.z),
                hc=hc, sh=sh, base=base, hip_z=hip_z, tw=tw, td=td, th=th, top=sh.z + .05, lw=lw)


def smooth(ctrl, n):
    """Catmull-Rom through (x,y,z,w) control points, n samples per span -> list of (V, width)"""
    P, W, m, out = [V(c[:3]) for c in ctrl], [c[3] for c in ctrl], len(ctrl), []
    for i in range(m - 1):
        p0, p1, p2, p3 = P[max(i - 1, 0)], P[i], P[i + 1], P[min(i + 2, m - 1)]
        for k in range(n):
            t = k / n
            pt = .5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)
            out.append((pt, W[i] + (W[i + 1] - W[i]) * t))
    out.append((P[-1], W[-1]))
    return out


def serpent(B, A, p, s):
    n = s.get("n", 3)
    pts = smooth(s["path"], n)  # control points (x, y, z, width) from neck to tail tip
    fl = s.get("flat", 1)
    for i in range(len(pts) - 1):
        (a, wa), (b, wb) = pts[i], pts[i + 1]
        col = s["bands"] if (s.get("bands") and (i // n) % 2) else "main"
        B.seg(a, b, wa, wa * fl, col, t0=1, t1=wb / wa)
        B.box(b, (wb, wb * fl, wb), col)
    hs = s["head"]
    hw, hd, hh = hs.get("size", (.5, .45, .42))
    hc = pts[0][0] + V((0, -hd * .15, hh * .35))
    head(B, A, p, hs, s.get("face", {}), hc)
    for fi in s.get("fins", []):  # (control index, color, w, h)
        q, wq = pts[min(fi[0] * n, len(pts) - 1)]
        B.box((q.x + wq / 2 + fi[2] * .3, q.y, q.z), (fi[2] * .6, .05, fi[3] * .6), fi[1], rot=(0, -30, 0), mirror=True)
    end = pts[-1][0]
    if s.get("tailfin"):
        B.box((end.x, end.y + .05, end.z + .05), (s["tailfin"][1], .06, s["tailfin"][0]), s.get("tailfin_color", "accent"), top=(1.3, 1))
    q = pts[min(2 * n, len(pts) - 1)]
    return dict(wing_root=(q[1] / 2, q[0].y, q[0].z + .05), spine_a=pts[-3][0], spine_b=pts[1][0], hc=hc)


def blob(B, A, p, s):
    bw, bd, bh = s.get("body", (.7, .6, .7))
    z0 = s.get("lift", .18)
    zc = z0 + bh / 2
    bf = {"-z": "belly", **s.get("body_faces", {})}
    if not s.get("head") and s.get("face") is not None:
        face(A, p, "bface", max(int(bw * 400), 32), max(int(bh * 400), 32), s["face"])
        bf["-y"] = "bface"
    B.box((0, 0, zc), (bw, bd, bh), s.get("body_color", "main"), faces=bf, top=s.get("body_top", (.8, .85)),
          bot=s.get("body_bot", (.8, .85)))
    if s.get("chest", True):
        B.box((0, -bd / 2 + .03, zc - bh * .08), (bw * .65, .06, bh * .6), "belly")
    for sx in (1, -1) if not s.get("no_feet") else ():
        B.box((sx * bw * .25, -bd * .1, z0 / 2), (.14, .22, z0 + .02), s.get("foot_color", "sub"))
    hs = s.get("head")
    hc = V((0, -bd * .12, zc + bh / 2 + (hs.get("size", (.5, .45, .42))[2] * .35 if hs else 0)))
    if hs:
        head(B, A, p, hs, s.get("face", {}), hc)
    tail(B, A, p, s.get("tail"), V((0, bd / 2 - .05, zc - bh * .1)))
    return dict(wing_root=(bw / 2 * .8, 0, zc + bh * .1), spine_a=(0, bd / 2, zc + bh / 2), spine_b=(0, -bd / 2, zc + bh / 2), hc=hc,
                zc=zc, bw=bw, bd=bd, bh=bh)


def fish(B, A, p, s):
    bw, bl, bh = s.get("body", (.5, 1.2, .55))
    zc = s.get("z", .5)
    f = s.get("face", {})
    r = A.region("front", max(int(bw * 512), 32), max(int(bh * 512), 32))
    r.fill(S(*p["main"]))
    if f.get("mouth", True) == "smile":
        r.line((r.w * .2, r.h * .35), (r.w * .5, r.h * .2), 6, S(*p["black"]))
        r.line((r.w * .5, r.h * .2), (r.w * .8, r.h * .35), 6, S(*p["black"]))
    elif f.get("mouth", True):
        r.rect(r.w * .15, r.h * .22, r.w * .85, r.h * .42, S(*p["black"]))
        for i in range(6):
            r.rect(r.w * (.2 + i * .1), r.h * .36, r.w * (.24 + i * .1), r.h * .45, S(255, 255, 255))
    sides = {}
    for nm, ux in (("+x", .2), ("-x", .8)):
        rr = A.region("side" + nm, max(int(bl * 300), 32), max(int(bh * 300), 32))
        rr.fill(S(*p["main"]))
        rr.rect(0, 0, rr.w, rr.h * .3, S(*p[s.get("belly_side", "belly")]))
        R = rr.h * .1
        rr.ellipse(rr.w * ux, rr.h * .62, R * 1.2, R * 1.2, S(255, 255, 255))
        rr.ellipse(rr.w * ux, rr.h * .62, R * .7, R * .7, S(*p["black"]))
        sides[nm] = "side" + nm
    B.box((0, 0, zc), (bw, bl, bh), "main", faces={"-y": "front", "+x": sides["+x"], "-x": sides["-x"], "-z": "belly"},
          top=s.get("body_top", (.85, 1)), bot=(.8, 1))
    B.box((0, bl / 2 + .12, zc), (bw * .45, .35, bh * .5), "main", top=(.7, 1))
    B.box((0, bl / 2 + .38, zc + .05), (.06, .4, bh * 1.0), s.get("fin", "accent"), top=(1, 1), rot=(25, 0, 0))
    spike(B, (0, bl * .05, zc + bh / 2 - .05), (0, .6, 1), s.get("dorsal", .3), .08, s.get("fin", "accent"))
    for sx in (1, -1):
        B.box((sx * bw / 2, -bl * .1, zc - bh * .3), (.3, .18, .05), s.get("fin", "accent"), rot=(0, sx * 25, 0))
    return dict(wing_root=(bw / 2, 0, zc), spine_a=(0, bl / 2, zc + bh / 2), spine_b=(0, -bl / 3, zc + bh / 2), top=zc + bh / 2)


def custom(B, A, p, s):
    return {}


KINDS = dict(quad=quad, biped=biped, serpent=serpent, blob=blob, fish=fish, custom=custom)


def build(s, outdir, tex, name):
    A = L.Atlas()
    p = palette(A, s)
    B = L.Builder(A)
    ctx = KINDS[s.get("kind", "quad")](B, A, p, s)
    if s.get("wings"):
        wings(B, A, p, s["wings"], ctx["wing_root"])
    if s.get("spines"):
        spines(B, p, s["spines"], ctx["spine_a"], ctx["spine_b"])
    if s.get("shell"):
        sh = s["shell"]
        w_, l_, h_ = sh.get("size", (.5, .6, .3))
        r = A.region("shell", max(int(w_ * 400), 32), max(int(l_ * 400), 32))
        r.fill(S(*p[sh.get("color", "accent")]))
        r.bricks(8, 6, S(*p[sh.get("lines", "dark")]), r.X > -1)
        B.box((0, sh.get("y", 0), ctx["top"] + h_ / 2 - .04 + sh.get("dz", 0)), (w_, l_, h_), sh.get("color", "accent"),
              faces={"+z": "shell"}, top=(.8, .8))
    if s.get("extra"):
        s["extra"](B, A, p, ctx)
    return B.build(name, outdir, tex)
