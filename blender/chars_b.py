"""Specs 25-48"""
from cbase import *  # noqa: F403

# 25 - orca bird
SPECS[25] = dict(
    slug="orca_bird", kind="blob",
    pal=dict(main=(30, 140, 150), sub=(22, 24, 30), belly=(245, 245, 245), accent=(240, 240, 240), eye=(40, 150, 220)),
    body=(.8, .9, .7), lift=.35, foot_color="sub",
    head=dict(size=(.6, .55, .5), color="sub", beak=dict(size=(.28, .3, .12), color="sub"), crest=dict(n=1, color="sub", len=.3, r=.12)),
    face=dict(base="sub", eyes="cute", size=1.1, marks=[("dot", "white", .24, .8, 16), ("dot", "white", .76, .8, 16)]),
    wings=dict(kind="feather", span=.8, n=5, angle=20, color="main", rim="sub", chord=.55),
    tail=dict(n=3, len=.6, w=.25, w1=.35, a0=0, curve=-8, color="main", tip="fan", tipcolor="main", fan=.5),
)

# 26 - red/grey spiky armoured turtle
SPECS[26] = dict(
    slug="red_armor_beast", kind="quad",
    pal=dict(main=(180, 50, 40), sub=(70, 75, 70), belly=(215, 190, 140), accent=(150, 230, 40), eye=(240, 200, 40)),
    body=(.8, 1.1, .6), leg=.3, legw=.26, neck=(.1, .15), claws=True, paw="belly",
    head=dict(size=(.55, .5, .45), snout=dict(size=(.3, .3, .2), color="main", mouth="fangs", nose=None),
              horns=dict(color="belly", len=.3, out=.3, fwd=0, r=.06), crest=dict(n=3, color="belly", len=.25)),
    face=dict(eyes="slit", brow=True),
    shell=dict(size=(.7, .8, .3), color="sub", y=.1), spines=dict(n=3, color="accent", len=.45, r=.1),
    tail=dict(n=4, len=.9, w=.26, a0=5, curve=12, tip="blade", tipcolor="belly"), patches=[("sub", -.2, .0, .35, .3)],
)

# 27 - star kite with tentacles
def x27(B, A, p, c):
    zc = c["zc"]
    for sx in (1, -1):
        spike(B, (sx * .25, 0, zc), (sx, 0, 0), .5, .16, "main")
        for y in (-.12, .12):
            pts, _ = chain(B, (0, y, zc - .22), -62, -6, 4, .3, .07, .05, "sub", x=sx * .2)
            B.box(pts[-1], (.2, .2, .08), "main")
    spike(B, (0, 0, zc + .25), (0, 0, 1), .5, .2, "main")


SPECS[27] = dict(
    slug="star_kite", kind="blob", no_feet=True,
    pal=dict(main=(60, 110, 185), sub=(235, 200, 110), belly=(235, 215, 160), accent=(215, 185, 110), eye=(40, 130, 230)),
    body=(.5, .35, .5), lift=1.0, chest=False, body_color="belly", face=dict(base="belly", eyes="cute", size=1.5, mouth="smile"), extra=x27,
)

# 28 - orange/green lanky humanoid with tentacle arms
SPECS[28] = dict(
    slug="gem_tentacle", kind="biped",
    pal=dict(main=(215, 120, 40), sub=(50, 150, 110), belly=(235, 200, 140), accent=(220, 60, 140), eye=(150, 60, 160)),
    legs=(.5, .45), limb=.1, torso=(.4, .28, .5), pelvis=(.32, .25, .2), arm=(.5, .5), arm_color="sub", claws=False, hand=.14,
    leg_color="main", foot_color="sub", belly_plate=False,
    head=dict(size=(.46, .38, .38), ears=dict(kind="side", size=(.28, .08, .28), color="main", tilt=-15), crest=dict(n=1, color="sub", len=.25, r=.1)),
    face=dict(eyes="slit", brow=True, size=1.1), neck=(0, .1),
    extra=lambda B, A, p, c: B.box((c["sh"].x, c["sh"].y - c["td"] / 2 - .03, c["sh"].z - .22), (.16, .05, .22), "accent"),
)

# 29 - blue crystal dino
SPECS[29] = dict(
    slug="crystal_dino", kind="quad",
    pal=dict(main=(40, 110, 150), sub=(240, 225, 190), belly=(240, 225, 190), accent=(220, 100, 110), eye=(210, 100, 90), ice=(170, 215, 240)),
    body=(.6, 1.1, .55), leg=.35, legw=.2, neck=(.1, .45), sock="sub", claws=True, paw="sub",
    head=dict(size=(.4, .5, .36), snout=dict(size=(.22, .35, .16), color="main", mouth="smile", nose=None), crest=dict(n=4, color="ice", len=.4)),
    face=dict(eyes="angry", brow=True),
    spines=dict(n=6, color="ice", len=.5, r=.1),
    patches=[("accent", -.2, 0, .36, .36), ("sub", -.2, 0, .18, .18), ("accent", .3, 0, .3, .3)],
    tail=dict(n=4, len=.9, w=.2, a0=5, curve=8, tip="tuft", tipcolor="ice"),
)

# 30 - ornate blue turtle with two jars
def x30(B, A, p, c):
    for sx in (1, -1):
        B.box((sx * .2, .1, c["top"] + .42), (.26, .26, .3), "sub")
        B.box((sx * .2, .1, c["top"] + .58), (.2, .2, .03), "water")


SPECS[30] = dict(
    slug="jar_turtle", kind="quad",
    pal=dict(main=(50, 100, 170), sub=(225, 205, 160), belly=(225, 205, 160), accent=(150, 200, 225), eye=(50, 140, 200), water=(120, 200, 235)),
    body=(.85, 1.0, .45), leg=.2, legw=.26, neck=(.15, 0), paw="sub", sock="sub",
    head=dict(size=(.5, .5, .42), snout=None), face=dict(eyes="cute", mouth="smile"),
    shell=dict(size=(.8, .9, .3), color="accent", lines="main"), tail=dict(n=2, len=.3, w=.14, a0=10, curve=5), extra=x30,
)

# 31 - tractor farm diorama
def x31(B, A, p, c):
    B.box((0, 0, .05), (2.0, 2.0, .1), "dark")
    B.box((0, 0, .12), (1.8, 1.8, .06), "main")
    for i in range(5):
        B.box((-.1, -.7 + i * .18, .17), (1.2, .06, .04), "dark")
        for j in range(4):
            spike(B, (-.55 + j * .3, -.7 + i * .18, .17), (0, 0, 1), .12, .04, "sub")
    # artichoke
    B.box((-.55, .55, .55), (.5, .5, .6), "belly", top=(.8, .8))
    for k in range(6):
        a = k * 1.05
        spike(B, (-.55 + math.cos(a) * .15, .55 + math.sin(a) * .15, .8), (math.cos(a) * .4, math.sin(a) * .4, 1), .45, .1, "sub")
    for k in range(5):
        a = k * 1.26
        spike(B, (-.55 + math.cos(a) * .3, .55 + math.sin(a) * .3, .3), (math.cos(a) * .8, math.sin(a) * .8, 1.2), .6, .14, "sub")
    # tractor
    B.box((.35, -.3, .4), (.45, .75, .3), "sub")
    B.box((.35, -.5, .62), (.3, .3, .2), "accent")
    B.box((.35, .0, .6), (.4, .3, .08), "accent")
    for sx in (-1, 1):
        B.box((.35 + sx * .26, -.5, .27), (.14, .36, .36), "black")
        B.box((.35 + sx * .26, .1, .32), (.16, .46, .46), "black")
    B.box((.35, .0, .75), (.04, .04, .35), "accent")


SPECS[31] = dict(
    slug="tractor_farm", kind="custom",
    pal=dict(main=(110, 75, 40), sub=(70, 120, 40), belly=(185, 195, 70), accent=(225, 190, 80), dark=(60, 42, 25)), extra=x31,
)

# 32 - lotus plant beast
def x32(B, A, p, c):
    t = c["top"]
    for k in range(8):
        a = k * math.pi / 4
        spike(B, (math.cos(a) * .15, .05 + math.sin(a) * .15, t), (math.cos(a) * .9, math.sin(a) * .9, .9), .55, .14, "sub")
    for k in range(8):
        a = k * math.pi / 4 + .39
        spike(B, (math.cos(a) * .1, .05 + math.sin(a) * .1, t + .12), (math.cos(a) * .35, math.sin(a) * .35, 1), .5, .13, "accent")
    B.box((0, .05, t + .2), (.14, .14, .1), "brown")


SPECS[32] = dict(
    slug="lotus_beast", kind="quad",
    pal=dict(main=(110, 140, 55), sub=(60, 110, 40), belly=(190, 175, 90), accent=(235, 190, 70), eye=(235, 200, 60), brown=(110, 80, 50)),
    body=(.8, 1.0, .55), leg=.35, legw=.24, neck=(.1, .1), claws=True, sock="sub", paw="brown",
    head=dict(size=(.5, .5, .42), snout=dict(size=(.28, .4, .2), color="main", mouth="smile", nose=None), crest=dict(n=3, color="sub", len=.2)),
    face=dict(eyes="slit"), tail=dict(n=4, len=.8, w=.22, a0=5, curve=8, tip="tuft", tipcolor="sub"), extra=x32,
)

# 33 - ice lion-camel
def x33(B, A, p, c):
    B.box((0, .05, c["top"] + .2), (.42, .42, .4), "accent", top=(.6, .6))
    B.box((0, .05, c["top"] + .42), (.3, .3, .1), "white")


SPECS[33] = dict(
    slug="ice_camel_lion", kind="quad",
    pal=dict(main=(160, 200, 235), sub=(235, 230, 215), belly=(235, 230, 215), accent=(210, 185, 130), eye=(60, 160, 230), ice=(200, 230, 250)),
    body=(.55, 1.0, .5), leg=.4, legw=.17, neck=(0, .3), sock="accent", paw="sub", claws=True,
    head=dict(size=(.5, .5, .42), ears=dict(size=(.15, .06, .14), taper=.8, inner="sub"), snout=dict(size=(.22, .22, .15), color="belly", nose="black"),
              crest=dict(n=4, color="ice", len=.35)),
    face=dict(eyes="angry", brow=True),
    tail=dict(n=3, len=.5, w=.12, a0=10, curve=15, tip="fan", tipcolor="main", fan=.55), extra=x33,
)

# 34 - red fire-fox with leaves
SPECS[34] = dict(
    slug="red_fox_leaf", kind="quad",
    pal=dict(main=(205, 50, 35), sub=(60, 140, 50), belly=(230, 190, 110), accent=(60, 140, 50), eye=(230, 160, 40)),
    body=(.5, .9, .5), leg=.4, legw=.14, neck=(0, .15), sock="sub", paw="belly",
    head=dict(size=(.5, .46, .42), ears=dict(size=(.22, .06, .45), tilt=8, taper=.3, inner="belly"),
              snout=dict(size=(.2, .25, .15), color="belly", nose="black", mouth=None), mane=dict(color="main", n=9, len=.3, r=.11),
              crest=dict(n=2, color="accent", len=.3, r=.06)),
    face=dict(eyes="angry", brow=True), spines=dict(n=4, color="accent", len=.2),
    tail=dict(n=4, len=.9, w=.22, a0=20, curve=20, tip="tuft", tipcolor="main"),
)

# 35 - blue masked frog-ninja
SPECS[35] = dict(
    slug="ninja_frog", kind="biped",
    pal=dict(main=(25, 50, 150), sub=(160, 210, 240), belly=(240, 240, 240), accent=(220, 40, 40), eye=(220, 30, 30)),
    legs=(.45, .45), limb=.13, knee=.22, lean=30, torso=(.4, .3, .4), pelvis=(.4, .3, .22), arm=(.45, .45), arm_fwd=.15, hand=.2,
    hand_color="sub", foot=.4, foot_color="sub", claws=False, belly_plate=False, neck=(.1, .0),
    head=dict(size=(.6, .5, .45), ears=dict(size=(.3, .05, .28), tilt=40, taper=.15, inner="sub"), mane=dict(color="sub", n=9, len=.3, r=.1)),
    face=dict(base="belly", eyes="glow", size=1.3, brow=True, ey=.55),
    tail=dict(n=2, len=.4, w=.14, a0=10, curve=15, color="main"),
)

# 36 - pineapple shark
def x36(B, A, p, c):
    t = c["top"]
    B.box((0, .3, t - .35), (.67, .7, .72), "sub")
    for k in range(7):
        spike(B, (0, .1 + k * .07, t), (math.sin(k - 3) * .5, .15, 1), .4, .06, "accent")


SPECS[36] = dict(
    slug="pineapple_shark", kind="fish",
    pal=dict(main=(40, 120, 200), sub=(240, 180, 30), belly=(240, 235, 225), accent=(70, 150, 50), eye=(20, 20, 24)),
    body=(.65, 1.3, .7), z=.55, fin="main", extra=x36,
)

# 37 - monkey drum robot
def x37(B, A, p, c):
    B.box(c["hc"] + V((0, 0, .33)), (.6, .6, .18), "belly")
    B.box(c["hc"] + V((0, 0, .25)), (.64, .64, .06), "sub")
    chest_disc(B, A, p, c, "target", size=.3, dz=-.25, bg="sub", fg="belly", kind="ring")


SPECS[37] = dict(
    slug="drum_monkey", kind="biped",
    pal=dict(main=(185, 120, 55), sub=(205, 70, 35), belly=(225, 185, 120), accent=(205, 70, 35), eye=(40, 25, 20)),
    legs=(.35, .35), limb=.2, torso=(.5, .4, .5), pelvis=(.45, .35, .22), lean=8, pads="sub", arm=(.35, .35), hand=.28, foot_color="sub",
    belly_plate=False, claws=False,
    head=dict(size=(.6, .5, .5), snout=dict(size=(.3, .18, .2), color="belly", nose="main", mouth="smile"),
              ears=dict(kind="side", size=(.2, .1, .2), color="main", tilt=0)),
    face=dict(eyes="cute", size=1.5, marks=[("dot", "sub", .22, .55, 22), ("dot", "sub", .78, .55, 22)]),
    tail=dict(n=6, len=1.1, w=.14, a0=-20, curve=16, color="main", color2="sub", tip="blade", tipcolor="sub"), extra=x37, neck=(0, .0),
)

# 38 - treant wolf
SPECS[38] = dict(
    slug="treant_wolf", kind="biped",
    pal=dict(main=(95, 110, 55), sub=(70, 60, 40), belly=(130, 125, 70), accent=(60, 140, 110), eye=(200, 200, 60)),
    legs=(.4, .4), limb=.24, torso=(.75, .45, .7), pelvis=(.55, .4, .26), pads="accent", arm=(.4, .4), hand=.3, foot_color="sub",
    head=dict(size=(.46, .46, .42), snout=dict(size=(.22, .35, .16), color="belly", nose="black", mouth=None), ears=dict(size=(.17, .06, .4), taper=.3),
              horns=dict(color="sub", len=.55, out=.3, fwd=0, r=.05)),
    face=dict(eyes="angry", brow=True), tail=dict(n=3, len=.6, w=.2, a0=-10, curve=-8, tip="tuft", tipcolor="accent"), neck=(0, .1),
)

# 39 - ice camel-dino
def x39(B, A, p, c):
    b = c["base"]
    B.box((0, b.y + .15, b.z + .42), (.5, .5, .35), "sub", top=(.8, .8))
    B.box((0, b.y - .15, b.z + .45), (.4, .35, .3), "sub", top=(.7, .7))


SPECS[39] = dict(
    slug="ice_camel_dino", kind="biped",
    pal=dict(main=(215, 175, 100), sub=(170, 210, 235), belly=(225, 195, 125), accent=(100, 170, 70), eye=(60, 160, 230)),
    legs=(.75, .7), limb=.14, torso=(.5, .7, .5), pelvis=(.4, .5, .22), lean=62, arm=(.4, .4), arm_color="accent", hand_color="accent", belly_plate=False,
    neck=(.35, .5), foot_color="main",
    head=dict(size=(.34, .45, .3), snout=dict(size=(.18, .25, .14), color="belly", nose="black", mouth=None), crest=dict(n=3, color="sub", len=.25)),
    face=dict(eyes="cute"), tail=dict(n=5, len=1.0, w=.16, a0=5, curve=5, tip="tuft", tipcolor="accent"), extra=x39,
)

# 40 - penguin knight
def x40(B, A, p, c):
    B.box((0, -.31, c["zc"]), (.34, .06, .85), "sub")
    B.box((0, -.34, c["zc"]), (.08, .06, .85), "accent")


SPECS[40] = dict(
    slug="penguin_knight", kind="blob",
    pal=dict(main=(30, 45, 80), sub=(215, 185, 130), belly=(40, 55, 95), accent=(220, 95, 40), eye=(60, 160, 230)),
    body=(.85, .6, 1.0), lift=.2, chest=False, foot_color="accent",
    head=dict(size=(.55, .45, .42), beak=dict(size=(.18, .3, .12), color="accent"), crest=dict(n=3, color="sub", len=.4, r=.07)),
    face=dict(eyes="angry", brow=True),
    wings=dict(kind="fin", span=.5, chord=.8, angle=-55, color="main", rim="sub"), extra=x40,
)

# 41 - dark wolf
SPECS[41] = dict(
    slug="void_wolf", kind="biped",
    pal=dict(main=(40, 40, 85), sub=(120, 120, 200), belly=(110, 100, 170), accent=(150, 150, 230), eye=(150, 200, 255)),
    legs=(.45, .4), limb=.17, knee=.18, lean=20, torso=(.5, .38, .5), pelvis=(.42, .32, .22), hand=.22, hand_color="sub", foot_color="sub",
    head=dict(size=(.45, .45, .4), snout=dict(size=(.22, .35, .16), color="belly", nose="black", mouth=None),
              ears=dict(size=(.17, .06, .4), taper=.3, inner="sub"), mane=dict(color="main", n=9, len=.35, r=.14)),
    face=dict(eyes="angry", brow=True), neck=(.1, .1),
    tail=dict(n=4, len=.9, w=.28, a0=10, curve=12, tip="tuft", tipcolor="accent"),
    patches=None,
)

# 42 - red/tan croc with blades
def x42(B, A, p, c):
    for sx in (1, -1):
        spike(B, (sx * .3, c["sh"].y + .2, c["sh"].z + .1), (sx * .6, .9, .7), .8, .12, "accent")


SPECS[42] = dict(
    slug="blade_croc", kind="biped",
    pal=dict(main=(185, 160, 95), sub=(60, 45, 40), belly=(185, 160, 95), accent=(200, 40, 40), eye=(240, 170, 30)),
    legs=(.4, .4), limb=.2, torso=(.58, .42, .55), pelvis=(.5, .38, .24), lean=20, arm=(.32, .32), arm_color="sub", leg_color="sub", pads="sub",
    head=dict(size=(.44, .5, .36), snout=dict(size=(.28, .5, .2), color="main", mouth="fangs", nose=None, dz=-.1), crest=dict(n=3, color="accent", len=.25)),
    face=dict(eyes="slit", brow=True), neck=(.1, .1),
    tail=dict(n=5, len=1.0, w=.26, a0=-5, curve=10, color="main", color2="sub", tip="blade", tipcolor="accent"), extra=x42,
)

# 43 - green/yellow sky serpent
SPECS[43] = dict(
    slug="sky_serpent_2", kind="serpent",
    pal=dict(main=(60, 170, 70), sub=(235, 225, 190), accent=(210, 50, 40), eye=(240, 190, 30), yellow=(240, 210, 50)),
    path=[(0, 0, 1.6, .2), (0, .35, 1.3, .22), (0, .45, .9, .22), (0, .2, .55, .2), (0, -.2, .45, .19), (0, -.55, .6, .17),
          (0, -.6, 1.0, .14), (0, -.3, 1.2, .1), (0, .0, 1.05, .07)],
    n=3, bands="yellow", flat=.95,
    head=dict(size=(.4, .5, .3), snout=dict(size=(.25, .35, .15), color="main", mouth="fangs", nose=None), horns=dict(color="main", len=.6, fwd=-.5, out=.4, r=.05)),
    face=dict(eyes="slit"), tailfin=(.4, .4), fins=[(2, "sub", .3, .3), (5, "sub", .3, .3)],
)

# 44 - black dragon with blade claws
def x44(B, A, p, c):
    for sx in (1, -1):
        spike(B, (sx * .4, -.35, c["top"] - .15), (sx * .4, -.5, -.9), .8, .14, "steel")


SPECS[44] = dict(
    slug="black_dragon", kind="quad",
    pal=dict(main=(30, 36, 50), sub=(200, 50, 50), belly=(215, 190, 140), accent=(200, 50, 50), eye=(230, 200, 60), steel=(150, 155, 160), wing=(40, 48, 66)),
    body=(.7, 1.0, .6), leg=.3, legw=.22, neck=(.15, .2), claws=True, paw="belly",
    head=dict(size=(.5, .5, .42), snout=dict(size=(.28, .36, .2), color="main", mouth="fangs", nose=None), horns=dict(color="sub", len=.35, out=.5)),
    face=dict(eyes="slit", brow=True), wings=dict(kind="bat", span=1.1, chord=.7, angle=50, color="wing", rim="sub"),
    spines=dict(n=5, color="belly", len=.2), tail=dict(n=4, len=.9, w=.24, a0=-5, curve=8, tip="blade", tipcolor="belly"), extra=x44,
)

# 45 - white sky guardian
SPECS[45] = dict(
    slug="white_guardian", kind="biped", no_arms=True,
    pal=dict(main=(240, 240, 242), sub=(80, 100, 170), belly=(150, 165, 220), accent=(60, 70, 140), eye=(30, 30, 40)),
    legs=(.3, .3), limb=.12, torso=(.6, .45, .7), pelvis=(.5, .4, .25), lean=8, neck=(.15, .4), foot_color="main", claws=True,
    head=dict(size=(.4, .44, .36), snout=dict(size=(.2, .25, .14), color="main", mouth=None, nose=None), crest=dict(n=4, color="sub", len=.35)),
    face=dict(eyes="slit", brow=False, size=1.0),
    wings=dict(kind="feather", span=1.0, n=5, angle=45, color="main", rim="sub", chord=.6),
    tail=dict(n=3, len=.7, w=.15, a0=-5, curve=10, tip="blade", tipcolor="accent"),
)

# 46 - owl griffin
SPECS[46] = dict(
    slug="owl_griffin", kind="quad",
    pal=dict(main=(60, 130, 120), sub=(225, 215, 170), belly=(225, 215, 170), accent=(225, 215, 170), eye=(235, 200, 50), beakc=(150, 140, 110)),
    body=(.65, .9, .65), leg=.38, legw=.14, neck=(0, .2), claws=True, paw="sub", sock="sub",
    head=dict(size=(.5, .46, .44), beak=dict(size=(.22, .3, .2), color="beakc"), crest=dict(n=5, color="sub", len=.28)),
    face=dict(eyes="slit", base="main"),
    wings=dict(kind="feather", span=.8, n=5, angle=15, color="main", rim="sub", chord=.6),
    tail=dict(n=3, len=.6, w=.3, a0=-10, curve=-8, tip="fan", tipcolor="sub"),
)

# 47 - duck-bill lion
SPECS[47] = dict(
    slug="duckbill_lion", kind="quad",
    pal=dict(main=(30, 120, 90), sub=(235, 220, 160), belly=(235, 220, 160), accent=(240, 210, 40), eye=(230, 190, 40)),
    body=(.55, 1.0, .55), leg=.35, legw=.18, neck=(0, .1), claws=True, paw="sub", stripes=("sub", 2, .06),
    head=dict(size=(.5, .5, .44), snout=dict(size=(.36, .4, .14), color="accent", mouth=None, nose=None, dz=-.12),
              mane=dict(color="sub", n=11, len=.35, r=.13), crest=dict(n=4, color="main", len=.35)),
    face=dict(eyes="angry", brow=True), tail=dict(n=3, len=.6, w=.12, a0=15, curve=18, tip="tuft", tipcolor="main"),
)

# 48 - sea-dragon serpent
SPECS[48] = dict(
    slug="sea_serpent", kind="serpent",
    pal=dict(main=(80, 130, 170), sub=(225, 215, 190), accent=(200, 225, 235), eye=(60, 120, 190), coral=(100, 170, 190)),
    path=[(0, 0, 1.0, .22), (0, .25, .8, .24), (0, .45, .5, .24), (0, .3, .25, .22), (0, -.1, .15, .2), (0, -.5, .22, .18),
          (0, -.7, .5, .15), (0, -.55, .8, .12), (0, -.25, .9, .08)],
    n=3, bands="sub", flat=.9,
    head=dict(size=(.42, .5, .34), snout=dict(size=(.24, .35, .15), color="main", mouth="fangs", nose=None),
              horns=dict(color="sub", len=.45, fwd=-.1, out=.2, r=.08), crest=dict(n=5, color="coral", len=.3)),
    face=dict(eyes="slit"), tailfin=(.5, .5), tailfin_color="accent",
    fins=[(2, "accent", .35, .3), (4, "accent", .3, .25), (6, "accent", .3, .25)],
)
