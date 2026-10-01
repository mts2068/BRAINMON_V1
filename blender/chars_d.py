"""Specs 73-88"""
from cbase import *  # noqa: F403


# 73 - goat-snail (lavender, brown spots, shell)
def x73(B, A, p, c):
    y = c["sh"].y + c["td"] / 2 + .2
    B.box((0, y, c["sh"].z - .3), (.7, .55, .6), "sub", top=(.85, .85))
    for k in range(3):
        B.box((0, y, c["sh"].z - .5 + k * .2), (.76, .6, .06), "accent")
    for sx, sz in ((1, -.55), (-1, -.8)):
        B.box((sx * .3, c["sh"].y - c["td"] / 2 - .03, c["sh"].z + sz), (.18, .04, .22), "accent")


SPECS[73] = dict(
    slug="goat_snail", kind="biped",
    pal=dict(main=(190, 170, 215), sub=(215, 165, 95), belly=(235, 200, 140), accent=(120, 70, 40), eye=(150, 90, 190)),
    legs=(.2, .2), limb=.24, torso=(.8, .6, .75), pelvis=(.7, .55, .3), arm=(.3, .3), hand=.22, claws=False, foot_color="belly", neck=(0, .35),
    head=dict(size=(.46, .46, .4), snout=dict(size=(.22, .25, .15), color="belly", mouth="smile", nose=None), horns=dict(color="sub", len=.45, out=.6, r=.08),
              ears=dict(kind="side", size=(.18, .06, .14), color="main")),
    face=dict(eyes="cute", size=1.1, mouth=None), tail=dict(n=4, len=.8, w=.3, a0=0, curve=18, tip="ball", tipcolor="main"), extra=x73,
)


# 74 - coffee-cup armoured ballerina with blades
def x74(B, A, p, c):
    hz, sh = c["hip_z"], c["sh"]
    skirt(B, hz, .85, .14, "sub", 2, .5)
    latte(B, A, p, c["hc"] + V((0, 0, .34)), (.44, .44, .2), cup="sub", foam="sub", art="accent")
    for sx in (1, -1):
        B.seg((sx * .38, sh.y - .1, sh.z - .5), (sx * .55, sh.y - .5, sh.z - 1.2), .07, .04, "accent")


SPECS[74] = dict(
    slug="latte_warrior", kind="biped",
    pal=dict(main=(135, 90, 160), sub=(215, 185, 140), belly=(135, 90, 160), accent=(190, 120, 240), eye=(190, 100, 230)),
    legs=(.5, .45), limb=.1, torso=(.32, .22, .42), pelvis=(.34, .24, .14), arm=(.3, .3), hand=.12, claws=False, foot_color="sub", torso_color="sub",
    belly_plate=False, pads="sub", head=dict(size=(.46, .42, .42)), face=dict(eyes="glow", size=1.0), neck=(0, .05), extra=x74,
)

# 75 - radioactive dark godzilla
SPECS[75] = dict(
    slug="radiation_zilla", kind="biped",
    pal=dict(main=(50, 62, 80), sub=(110, 125, 90), belly=(100, 115, 90), accent=(160, 230, 40), eye=(210, 240, 50), dark=(35, 44, 58)),
    legs=(.4, .4), limb=.25, torso=(.72, .5, .65), pelvis=(.58, .42, .26), lean=10, pads="sub", arm=(.35, .35), hand=.3, foot_color="main",
    head=dict(size=(.46, .5, .38), snout=dict(size=(.3, .42, .2), color="main", mouth="fangs", nose=None, dz=-.1), crest=dict(n=3, color="sub", len=.25)),
    face=dict(eyes="glow", brow=True), neck=(.1, .1), spines=dict(n=5, color="sub", len=.5, r=.12),
    tail=dict(n=5, len=1.0, w=.3, a0=-5, curve=9, tip="ball", tipcolor="sub"),
    extra=lambda B, A, p, c: chest_disc(B, A, p, c, "rad2", size=.36, dz=-.22),
)

# 76 - leaf cat fairy
SPECS[76] = dict(
    slug="leaf_cat", kind="biped",
    pal=dict(main=(40, 75, 50), sub=(235, 235, 215), belly=(235, 235, 215), accent=(130, 220, 170), eye=(190, 90, 190), wing=(150, 225, 180)),
    legs=(.45, .45), limb=.1, torso=(.32, .22, .4), pelvis=(.32, .24, .15), arm_color="sub", hand_color="sub", claws=False, foot_color="sub",
    belly_plate=False,
    head=dict(size=(.5, .44, .42), ears=dict(size=(.2, .06, .5), tilt=10, taper=.3, inner="accent"), mane=dict(color="accent", n=7, len=.25, r=.12)),
    face=dict(eyes="slit", size=1.0), neck=(0, .05),
    wings=dict(kind="butterfly", span=.8, chord=.6, angle=40, color="wing", rim="main"),
    tail=dict(n=3, len=.6, w=.1, a0=-10, curve=22, color="main", tip="leaf", tipcolor="accent"),
)

# 77 - hooded frog
SPECS[77] = dict(
    slug="hood_frog", kind="biped",
    pal=dict(main=(30, 130, 140), sub=(150, 200, 170), belly=(210, 225, 190), accent=(220, 140, 60), eye=(20, 30, 40), dark=(25, 28, 40)),
    legs=(.45, .45), limb=.12, knee=.2, lean=15, torso=(.38, .28, .42), pelvis=(.38, .28, .2), arm=(.45, .4), hand=.3, foot=.5, foot_color="main", claws=False,
    head=dict(size=(.6, .5, .5), color="dark", crest=dict(n=3, color="main", len=.3)),
    face=dict(eyes="cute", size=1.2, mouth="smile"), neck=(.1, .0),
    extra=lambda B, A, p, c: B.box((0, c["sh"].y + .2, c["sh"].z - .35), (.6, .06, .7), "dark"),
)


# 78 - owl-fairy archer
def x78(B, A, p, c):
    pts = [(-.6, -.35, 1.15), (-.75, -.35, .88), (-.75, -.35, .6), (-.6, -.35, .33)]
    for a, b in zip(pts, pts[1:]):
        B.seg(a, b, .05, .05, "main")
    B.seg(pts[0], pts[-1], .015, .015, "sub")


SPECS[78] = dict(
    slug="owl_archer", kind="biped",
    pal=dict(main=(60, 150, 110), sub=(235, 235, 215), belly=(235, 235, 215), accent=(180, 90, 190), eye=(190, 90, 190), wing=(170, 225, 190)),
    legs=(.4, .4), limb=.1, torso=(.36, .26, .45), pelvis=(.36, .26, .18), arm_color="sub", hand_color="sub", claws=False, foot_color="main",
    belly_plate=True, head=dict(size=(.55, .46, .46), color="main", crest=dict(n=3, color="accent", len=.25, r=.07)),
    face=dict(eyes="slit", base="sub", brow=True), neck=(0, .05),
    wings=dict(kind="feather", span=.9, n=5, angle=40, color="wing", rim="main", chord=.6), extra=x78,
)


# 79 - ice mammoth
def x79(B, A, p, c):
    hc = c["hc"]
    for sx in (1, -1):
        B.seg((sx * .2, hc.y - .22, hc.z - .15), (sx * .38, hc.y - .55, hc.z - .55), .12, .12, "belly", t1=.7)
        B.seg((sx * .38, hc.y - .55, hc.z - .55), (sx * .25, hc.y - .85, hc.z - .35), .1, .1, "belly", t1=.4)


SPECS[79] = dict(
    slug="ice_mammoth", kind="quad",
    pal=dict(main=(205, 170, 115), sub=(160, 205, 215), belly=(240, 235, 220), accent=(60, 170, 170), eye=(60, 160, 190)),
    body=(.9, 1.1, .8), leg=.35, legw=.3, neck=(0, 0), paw="belly", sock="sub", chest=False,
    head=dict(size=(.7, .6, .6), snout=dict(size=(.2, .45, .22), color="sub", mouth=None, nose=None, dz=-.15), mane=dict(color="main", n=9, len=.3, r=.14)),
    face=dict(eyes="angry", brow=True, base="main", lower="belly"), spines=dict(n=4, color="sub", len=.45, r=.12),
    tail=dict(n=2, len=.3, w=.12, a0=-20, curve=-10, tip="tuft", tipcolor="main"), extra=x79,
)

# 80 - leafy sea dragon (vertical)
SPECS[80] = dict(
    slug="leaf_seadragon", kind="serpent",
    pal=dict(main=(25, 28, 50), sub=(235, 235, 235), accent=(50, 70, 160), eye=(200, 40, 50)),
    path=[(0, 0, 1.8, .16), (0, .12, 1.4, .18), (0, .22, 1.0, .18), (0, .08, .6, .16), (0, -.1, .35, .14), (0, .0, .15, .11), (0, .2, .1, .07)],
    n=3, bands="sub", flat=1.0,
    head=dict(size=(.34, .4, .3), snout=dict(size=(.14, .45, .14), color="main", mouth=None, nose=None), crest=dict(n=4, color="accent", len=.3)),
    face=dict(eyes="glow"), tailfin=(.3, .3), tailfin_color="accent",
    fins=[(1, "accent", .5, .45), (3, "accent", .5, .45)],
)

# 81 - radioactive lime humanoid
SPECS[81] = dict(
    slug="lime_guardian", kind="biped",
    pal=dict(main=(135, 140, 100), sub=(160, 230, 50), belly=(150, 155, 115), accent=(160, 230, 50), eye=(220, 240, 60), dark=(60, 70, 50)),
    legs=(.55, .5), limb=.13, knee=.15, torso=(.45, .3, .55), pelvis=(.36, .26, .2), pads="sub", arm=(.4, .4), hand=.2, foot_color="main",
    head=dict(size=(.4, .4, .36), crest=dict(n=4, color="sub", len=.35)), face=dict(eyes="slit", brow=True), neck=(0, .1),
    tail=dict(n=5, len=1.0, w=.16, a0=0, curve=12, tip="ball", tipcolor="sub"),
    extra=lambda B, A, p, c: chest_disc(B, A, p, c, "rad3", size=.3, dz=-.2),
)

# 82 - white armoured ballerina
def x82(B, A, p, c):
    hz, sh = c["hip_z"], c["sh"]
    skirt(B, hz, .85, .12, "main", 3, .5)
    B.box((0, 0, hz + .08), (.4, .3, .06), "sub")
    B.box(c["hc"] + V((0, .05, .3)), (.22, .22, .2), "sub")
    for sx in (1, -1):
        B.seg((sx * .3, sh.y, sh.z - .1), (sx * .8, sh.y - .2, sh.z - 1.0), .08, .05, "belly")


SPECS[82] = dict(
    slug="white_ballerina", kind="biped",
    pal=dict(main=(236, 230, 222), sub=(220, 175, 185), belly=(236, 230, 222), accent=(220, 175, 185), eye=(120, 160, 200)),
    legs=(.55, .45), limb=.1, torso=(.3, .2, .42), pelvis=(.32, .22, .14), arm=(.3, .3), hand=.12, claws=False, foot_color="main", belly_plate=False,
    head=dict(size=(.44, .4, .42)), face=dict(eyes="dot", size=1.0, mouth="smile"), neck=(0, .05), extra=x82,
)


# 83 - teal lantern bird
def x83(B, A, p, c):
    zc = c["zc"]
    B.box((0, -.36, zc), (.5, .04, .6), "sub")
    for sx in (1, -1):
        B.seg((sx * .45, 0, zc), (sx * .8, 0, zc + .3), .15, .15, "main")
        B.seg((sx * .8, 0, zc + .3), (sx * .62, 0, zc + .7), .12, .12, "main", t1=.6)
        B.seg((sx * .3, 0, zc - .4), (sx * .45, 0, zc - .85), .14, .14, "main", t1=.6)
    B.box((0, 0, zc - .5), (.14, .14, .2), "sub")


SPECS[83] = dict(
    slug="lantern_bird", kind="blob", no_feet=True,
    pal=dict(main=(40, 110, 120), sub=(70, 200, 200), belly=(70, 200, 200), accent=(70, 200, 200), eye=(40, 170, 200), beak=(230, 190, 60)),
    body=(.9, .7, .9), lift=.5, body_top=(.85, .85), chest=False,
    head=dict(size=(.5, .4, .4), beak=dict(size=(.14, .2, .1), color="beak"), crest=dict(n=3, color="main", len=.35, r=.12)),
    face=dict(eyes="cute", size=1.2), extra=x83,
)

# 84 - teal croc chibi godzilla
SPECS[84] = dict(
    slug="teal_zilla", kind="biped",
    pal=dict(main=(30, 150, 140), sub=(235, 215, 150), belly=(235, 215, 150), accent=(120, 215, 205), eye=(230, 150, 40)),
    legs=(.35, .3), limb=.22, torso=(.7, .5, .6), pelvis=(.56, .42, .24), lean=12, pads="accent", arm=(.3, .3), hand=.28, foot_color="sub",
    head=dict(size=(.5, .5, .4), snout=dict(size=(.3, .45, .2), color="main", mouth="fangs", nose=None, dz=-.1), crest=dict(n=5, color="accent", len=.3)),
    face=dict(eyes="slit", brow=True), neck=(.1, .1), spines=dict(n=5, color="accent", len=.3),
    tail=dict(n=5, len=1.0, w=.3, a0=-5, curve=9, tip="blade", tipcolor="accent"),
)


# 85 - coffee witch-hat girl
def x85(B, A, p, c):
    hc, hz = c["hc"], c["hip_z"]
    B.box(hc + V((0, 0, .26)), (.98, .98, .06), "main")
    B.box(hc + V((0, 0, .46)), (.45, .45, .4), "main", top=(.85, .85))
    B.box(hc + V((0, 0, .32)), (.47, .47, .08), "accent")
    B.box(hc + V((0, 0, .72)), (.15, .15, .14), "main")
    for sx in (1, -1):
        B.seg((sx * .28, hc.y + .05, hc.z), (sx * .45, hc.y + .05, hc.z - .85), .2, .12, "main", t1=.7)
        B.box((sx * .45, hc.y + .05, hc.z - .9), (.2, .14, .12), "main")
    skirt(B, hz, .6, .3, "belly", 1, .5)


SPECS[85] = dict(
    slug="latte_witch", kind="biped",
    pal=dict(main=(240, 225, 205), sub=(190, 135, 85), belly=(235, 220, 195), accent=(130, 80, 45), eye=(150, 95, 50)),
    legs=(.5, .45), limb=.1, torso=(.3, .2, .4), pelvis=(.32, .22, .14), arm=(.3, .28), hand=.12, claws=False, foot_color="sub", torso_color="sub",
    belly_plate=False, head=dict(size=(.46, .42, .44)), face=dict(eyes="cute", size=1.1, mouth="smile"), neck=(0, .05), extra=x85,
)


# 86 - lizardman totem warrior
def x86(B, A, p, c):
    chest_disc(B, A, p, c, "tgt", size=.36, dz=-.2, bg="sub", fg="accent", kind="ring")
    B.box((0, 1.3, .4), (.34, .55, .34), "sub")


SPECS[86] = dict(
    slug="totem_lizard", kind="biped",
    pal=dict(main=(45, 95, 70), sub=(160, 95, 55), belly=(200, 185, 120), accent=(205, 70, 50), eye=(60, 170, 190)),
    legs=(.42, .4), limb=.17, torso=(.5, .35, .55), pelvis=(.42, .32, .22), lean=10, pads="sub", arm=(.35, .35), hand=.2, foot_color="main",
    head=dict(size=(.42, .46, .36), snout=dict(size=(.2, .4, .15), color="main", mouth=None, nose=None, dz=-.1), crest=dict(n=5, color="sub", len=.3)),
    face=dict(eyes="slit"), neck=(.1, .1), tail=dict(n=5, len=1.0, w=.2, a0=0, curve=6, color="main", tip=None), extra=x86,
)

# 87 - white cloud bird
SPECS[87] = dict(
    slug="cloud_bird", kind="blob", no_feet=True,
    pal=dict(main=(245, 248, 248), sub=(80, 190, 190), belly=(250, 252, 252), accent=(80, 190, 190), eye=(40, 140, 150)),
    body=(.85, .75, .8), lift=.3, chest=False, face=dict(eyes="dot", size=1.5, mouth="smile", ey=.62),
    wings=dict(kind="fin", span=.8, chord=.5, angle=25, color="main", rim="sub", spots="accent"),
    tail=dict(n=2, len=.4, w=.2, a0=10, curve=15, tip="tuft", tipcolor="accent"),
    extra=lambda B, A, p, c: [spike(B, (k * .15, -.05, c["zc"] + c["bh"] / 2 - .05), (k * .5, 0, 1), .3, .09, "accent") for k in (-1, 0, 1)],
)

# 88 - armoured rhino beast
SPECS[88] = dict(
    slug="steel_rhino", kind="quad",
    pal=dict(main=(60, 75, 55), sub=(150, 152, 148), belly=(60, 75, 55), accent=(160, 225, 40), eye=(190, 230, 50)),
    body=(.9, 1.0, .7), leg=.3, legw=.28, neck=(.05, 0), claws=True, paw="sub", chest=False,
    head=dict(size=(.7, .6, .5), color="sub", horns=dict(color="sub", len=.45, r=.12, out=0, fwd=.2, x=0), crest=dict(n=2, color="sub", len=.25)),
    face=dict(eyes="glow", brow=True, base="sub"),
    shell=dict(size=(.8, .8, .3), color="sub", lines="main", y=.1), spines=dict(n=3, color="accent", len=.35, r=.1),
    tail=dict(n=4, len=.8, w=.24, a0=10, curve=14, tip="blade", tipcolor="sub"), patches=[("sub", 0, .0, .4, .35)],
)
