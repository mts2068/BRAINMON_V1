"""Specs 2-24"""
from cbase import *  # noqa: F403


# 2 - moth-spider (stone armour, orange wings)
def x2(B, A, p, c):
    legs6(B, .5, c["bw"], (-.3, 0, .3), "sub", reach=.6)


SPECS[2] = dict(
    slug="moth_spider", kind="blob",
    pal=dict(main=(78, 98, 52), sub=(150, 142, 122), belly=(225, 218, 196), accent=(232, 120, 30), eye=(190, 255, 40)),
    body=(.8, .9, .55), lift=.45, chest=False,
    head=dict(size=(.6, .5, .5), color="belly", horns=dict(color="main", len=.4, out=.5, fwd=-.2, r=.07),
              mane=dict(color="belly", n=7, len=.2, r=.12)),
    face=dict(eyes="slit", brow=True, base="belly"),
    wings=dict(kind="butterfly", span=1.0, chord=.9, angle=40, color="accent", rim="sub", spots="white"),
    tail=dict(n=3, len=.5, w=.3, a0=-15, curve=-10, color="main", color2="sub"), extra=x2,
)

# 3 - armored croc (radioactive)
SPECS[3] = dict(
    slug="armored_croc", kind="biped",
    pal=dict(main=(86, 98, 84), sub=(150, 152, 148), belly=(120, 130, 108), accent=(160, 224, 40), eye=(190, 235, 40), dark=(40, 48, 40)),
    legs=(.42, .4), limb=.22, torso=(.66, .45, .62), pelvis=(.54, .4, .26), lean=14, pads="sub", arm=(.35, .35), hand=.3,
    head=dict(size=(.46, .5, .38), snout=dict(size=(.3, .55, .2), color="main", mouth="fangs", nose=None, dz=-.1),
              crest=dict(n=3, color="sub", len=.22)),
    face=dict(eyes="slit", brow=True),
    tail=dict(n=5, len=1.0, w=.3, a0=-5, curve=9, color="main", tip="blade", tipcolor="sub"),
    spines=dict(n=5, color="sub", len=.24), neck=(.15, .1),
    extra=lambda B, A, p, c: chest_disc(B, A, p, c, "rad", dz=-.22),
)

# 4 - spiked maw monster
def x4(B, A, p, c):
    for sx in (1, -1):
        for y in (-.3, .3):
            B.box((sx * .38, y, .17), (.3, .34, .34), "main")
            for dx in (-.08, 0, .08):
                B.box((sx * .38 + dx, y - .2, .03), (.05, .06, .05), "sub")
        B.box((sx * .52, -.05, c["zc"] + .1), (.22, .3, .28), "sub")  # shoulder armour


SPECS[4] = dict(
    slug="maw_monster", kind="blob",
    pal=dict(main=(40, 62, 42), sub=(150, 155, 140), belly=(30, 45, 32), accent=(150, 230, 40), eye=(200, 255, 50), glow=(130, 220, 40)),
    body=(1.0, .9, .85), lift=.3, chest=False, face=dict(eyes="glow", brow=True, mouth="maw", ey=.8, sep=.22),
    spines=dict(n=7, color="sub", len=.4, r=.1),
    tail=dict(n=4, len=.9, w=.3, a0=0, curve=12, color="main", tip="blade", tipcolor="sub"), extra=x4,
)

# 5 - coffee ballerina
def x5(B, A, p, c):
    skirt(B, c["hip_z"] + .02, .85, .14, "belly", 2, .45)
    latte(B, A, p, c["hc"] + V((0, 0, .36)), (.5, .5, .24))


SPECS[5] = dict(
    slug="coffee_ballerina", kind="biped",
    pal=dict(main=(242, 234, 224), sub=(190, 140, 95), belly=(242, 234, 224), accent=(120, 70, 40), eye=(150, 100, 60)),
    legs=(.5, .45), limb=.11, torso=(.3, .2, .4), pelvis=(.32, .22, .14), arm=(.3, .28), hand=.12, claws=False, foot_color="sub",
    belly_plate=False, torso_color="belly",
    head=dict(size=(.5, .45, .45)), face=dict(eyes="cute", size=1.2, mouth="smile", cheek="sub"), neck=(0, .05), extra=x5,
)

# 6 - avocado deer
SPECS[6] = dict(
    slug="avocado_deer", kind="quad",
    pal=dict(main=(150, 190, 70), sub=(90, 150, 60), belly=(240, 226, 160), accent=(150, 95, 40), eye=(120, 70, 30)),
    body=(.55, 1.0, .55), leg=.4, legw=.14, neck=(0, .3), paw="accent", sock="sub",
    head=dict(size=(.5, .48, .45), ears=dict(size=(.22, .05, .45), tilt=35, color="sub", inner="belly", taper=.6),
              snout=dict(size=(.22, .3, .2), color="belly", nose="accent"), horns=dict(color="accent", len=.25, r=.05, out=.2)),
    face=dict(eyes="cute", size=1.1, mouth=None),
    tail=dict(n=2, len=.3, w=.12, a0=40, curve=10, tip="leaf", tipcolor="sub"),
    patches=[("sub", 0, .02, .4, .42), ("accent", .0, -.02, .14, .16)], spines=dict(n=4, color="sub", len=.28, r=.09),
)

# 7 - cat-chameleon
SPECS[7] = dict(
    slug="cat_chameleon", kind="quad",
    pal=dict(main=(240, 210, 40), sub=(80, 170, 50), belly=(250, 240, 210), accent=(210, 60, 50), eye=(110, 70, 30)),
    body=(.5, .85, .5), leg=.3, legw=.15, neck=(0, .1), paw="belly", stripes=("sub", 3, .07),
    head=dict(size=(.6, .5, .5), ears=dict(size=(.18, .06, .3), tilt=10, taper=.3, color="main", inner="sub"),
              snout=dict(size=(.2, .12, .13), color="belly", nose="accent"), crest=dict(n=3, color="sub", len=.15, r=.1)),
    face=dict(eyes="cute", size=1.2, mouth="smile", cheek="accent"),
    tail=dict(n=7, len=1.2, w=.18, w1=.1, a0=15, curve=32, color="main", color2="sub", tip="ball", tipcolor="main"),
)

# 8 - tan bunny with teal markings
SPECS[8] = dict(
    slug="bunny_tan", kind="quad",
    pal=dict(main=(208, 170, 92), sub=(28, 138, 150), belly=(226, 198, 128), accent=(150, 98, 44), eye=(30, 140, 150)),
    body=(.5, .7, .5), leg=.3, legw=.15, neck=(0, .1),
    head=dict(size=(.62, .5, .5), ears=dict(size=(.17, .07, .5), tilt=8, taper=.5),
              snout=dict(size=(.2, .15, .14), nose="accent")),
    face=dict(eyes="cute", marks=[("spiral", "sub", .12, .4, 12)]),
    tail=dict(n=2, len=.3, w=.16, a0=25, curve=12, tip="blade", tipcolor="sub"), stripes=("sub", 2, .05),
)

# 9 - white winged flyer with coloured crystals
def x9(B, A, p, c):
    t = c["zc"] + c["bh"] / 2
    spike(B, (0, -.1, t), (0, 0, 1), .35, .12, "accent")
    for sx in (1, -1):
        spike(B, (sx * .22, -.05, t), (sx * .5, 0, 1), .25, .09, "red")


SPECS[9] = dict(
    slug="white_flyer", kind="blob",
    pal=dict(main=(242, 242, 240), sub=(215, 215, 208), belly=(250, 250, 250), accent=(80, 160, 225), eye=(20, 20, 24), red=(210, 60, 60)),
    body=(.85, .75, .8), lift=.25, chest=False, face=dict(eyes="dot", size=1.4, mouth="open", ey=.62, sep=.28),
    wings=dict(kind="fin", span=1.0, chord=.5, angle=12, color="main", rim="sub", spots="accent"),
    tail=dict(n=2, len=.4, w=.2, a0=10, curve=15, tip="tuft", tipcolor="main"), extra=x9,
)

# 10 - phoenix toucan
SPECS[10] = dict(
    slug="phoenix_toucan", kind="biped", no_arms=True,
    pal=dict(main=(235, 100, 30), sub=(250, 200, 40), belly=(240, 215, 150), accent=(120, 170, 40), eye=(250, 250, 250)),
    legs=(.35, .35), limb=.12, torso=(.55, .45, .55), pelvis=(.45, .4, .25), lean=20, foot_color="sub", leg_color="sub",
    head=dict(size=(.5, .5, .45), beak=dict(size=(.28, .5, .2), color="sub", lower="sub"), crest=dict(n=5, color="sub", len=.3, r=.06)),
    face=dict(eyes="dot", size=1.2, marks=[("spiral", "black", .75, .55, 14)]),
    wings=dict(kind="feather", span=1.1, n=6, angle=50, color="main", rim="sub", chord=.6),
    tail=dict(n=3, len=.8, w=.3, a0=-5, curve=-6, color="accent", tip="tuft", tipcolor="sub"), neck=(.1, .1),
)

# 11 - turtle dragon
def x11(B, A, p, c):
    sh = c["sh"]
    B.box((0, sh.y + c["td"] / 2 + .18, sh.z - .28), (.8, .4, .85), "sub", top=(.8, .8))
    B.box((0, sh.y + c["td"] / 2 + .3, sh.z - .28), (.5, .12, .55), "accent")


SPECS[11] = dict(
    slug="turtle_dragon", kind="biped", wings=None,
    pal=dict(main=(40, 160, 170), sub=(60, 130, 70), belly=(240, 225, 185), accent=(220, 60, 110), eye=(30, 90, 120)),
    legs=(.35, .35), limb=.2, torso=(.55, .42, .6), pelvis=(.5, .4, .24), lean=8, pads="accent", arm=(.3, .35),
    head=dict(size=(.46, .46, .4), snout=dict(size=(.22, .25, .15), color="main", mouth="smile", nose=None),
              crest=dict(n=4, color="accent", len=.25, r=.08), ears=dict(size=(.2, .05, .35), tilt=35, color="accent", inner="sub", taper=.4)),
    face=dict(eyes="cute", mouth=None),
    tail=dict(n=6, len=1.1, w=.22, a0=-5, curve=14, color="accent", color2="sub", tip="blade", tipcolor="main"), extra=x11,
)

# 12 - flower fairy
def x12(B, A, p, c):
    skirt(B, c["hip_z"] + .02, .55, .12, "sub", 2, .6)
    skirt(B, c["hip_z"] - .06, .5, .1, "accent", 1, .7)


SPECS[12] = dict(
    slug="flower_fairy", kind="biped",
    pal=dict(main=(238, 232, 175), sub=(240, 150, 170), belly=(238, 232, 175), accent=(130, 170, 50), eye=(40, 40, 50), wing=(200, 225, 130)),
    legs=(.25, .25), limb=.09, torso=(.3, .22, .35), pelvis=(.3, .22, .13), arm=(.25, .25), hand=.1, claws=False, foot_color="accent",
    belly_plate=False,
    head=dict(size=(.6, .52, .5), horns=dict(color="accent", len=.3, out=.2, fwd=0, r=.04), mane=dict(color="sub", n=9, len=.28, r=.12)),
    face=dict(eyes="cute", size=1.3, mouth="smile"),
    wings=dict(kind="butterfly", span=.8, chord=.6, angle=35, color="wing", rim="accent", spots="sub"), extra=x12, neck=(0, .05),
)

# 13 - teal flying whale-turtle
def x13(B, A, p, c):
    zc = c["zc"]
    for sx in (1, -1):
        for y in (-.35, .3):
            B.box((sx * .55, y, zc - .15), (.45, .3, .08), "belly", rot=(0, sx * 20, 0))
    B.box((0, .8, zc + .15), (.08, .4, .55), "sub", rot=(-25, 0, 0))


SPECS[13] = dict(
    slug="sky_whale", kind="blob",
    pal=dict(main=(30, 120, 140), sub=(230, 110, 80), belly=(150, 195, 205), accent=(60, 170, 190), eye=(230, 160, 50)),
    body=(.85, 1.3, .6), lift=.45, chest=False, face=dict(eyes="cute", size=1.2, ey=.65, sep=.22),
    spines=dict(n=5, color="sub", len=.2, r=.08), extra=x13,
)

# 14 - teal winged dragon (quad)
SPECS[14] = dict(
    slug="teal_dragon", kind="quad",
    pal=dict(main=(30, 140, 150), sub=(225, 100, 80), belly=(235, 215, 170), accent=(225, 100, 80), eye=(230, 170, 40), wing=(50, 110, 128)),
    body=(.6, 1.0, .55), leg=.3, legw=.2, neck=(.1, .3), claws=True, paw="belly",
    head=dict(size=(.5, .5, .42), snout=dict(size=(.26, .32, .18), color="main", mouth="fangs", nose=None),
              horns=dict(color="sub", len=.3, out=.3, fwd=-.3), crest=dict(n=3, color="sub", len=.2)),
    face=dict(eyes="slit", brow=True),
    wings=dict(kind="bat", span=1.0, chord=.7, angle=45, color="wing", rim="sub"),
    tail=dict(n=5, len=.9, w=.22, a0=-5, curve=9, tip="fan", tipcolor="sub"), spines=dict(n=5, color="sub", len=.2),
)

# 15 - three-headed black hydra
def x15(B, A, p, c):
    hs = dict(size=(.4, .42, .34), snout=dict(size=(.24, .3, .16), color="main", mouth="fangs", nose=None, dz=-.08), crest=dict(n=3, color="accent", len=.2))
    for k, sx in enumerate((1, -1)):
        hc = c["hc"] + V((sx * .5, -.05, .05))
        B.seg(c["sh"] + V((sx * .1, 0, -.05)), hc + V((0, .05, -.1)), .2, .2, "main")
        head(B, A, p, hs, dict(eyes="slit", brow=True), hc, tag=f"face{k + 2}")


SPECS[15] = dict(
    slug="hydra_black", kind="biped",
    pal=dict(main=(30, 32, 40), sub=(235, 215, 170), belly=(235, 215, 170), accent=(190, 40, 40), eye=(255, 200, 60)),
    legs=(.42, .4), limb=.2, torso=(.55, .42, .6), pelvis=(.5, .38, .24), lean=12, pads="accent", arm=(.3, .35), neck=(.1, .15),
    head=dict(size=(.4, .42, .34), snout=dict(size=(.24, .3, .16), color="main", mouth="fangs", nose=None, dz=-.08), crest=dict(n=3, color="accent", len=.2)),
    face=dict(eyes="slit", brow=True),
    wings=dict(kind="feather", span=1.0, n=5, angle=55, color="accent", rim="sub", chord=.55),
    tail=dict(n=5, len=1.0, w=.28, a0=-5, curve=9, color="main", tip="tuft", tipcolor="accent"), spines=dict(n=4, color="sub", len=.22),
    extra=x15,
)

# 16 - moth (cream/orange)
def x16(B, A, p, c):
    legs6(B, .4, c["bw"], (-.2, 0, .2), "leg", reach=.45)


SPECS[16] = dict(
    slug="moth_cream", kind="blob",
    pal=dict(main=(235, 205, 150), sub=(215, 130, 50), belly=(245, 225, 180), accent=(230, 140, 50), eye=(230, 140, 30), leg=(120, 95, 70)),
    body=(.75, .75, .6), lift=.4,
    head=dict(size=(.6, .5, .5), horns=dict(color="accent", len=.4, out=.35, fwd=-.1, r=.06), mane=dict(color="belly", n=7, len=.2, r=.12)),
    face=dict(eyes="cute", size=1.3, mouth="smile"),
    wings=dict(kind="butterfly", span=.95, chord=.85, angle=40, color="accent", rim="main", spots="belly"), extra=x16,
)

# 17 - purple bat dragon with gold
SPECS[17] = dict(
    slug="night_batdragon", kind="biped",
    pal=dict(main=(45, 35, 100), sub=(230, 200, 90), belly=(235, 235, 230), accent=(230, 200, 90), eye=(220, 50, 200), wing=(70, 45, 130)),
    legs=(.4, .4), limb=.14, torso=(.45, .35, .5), pelvis=(.4, .3, .22), lean=8, arm=(.3, .3), hand=.18, neck=(.1, .15), foot_color="sub",
    head=dict(size=(.46, .46, .4), snout=dict(size=(.2, .3, .14), color="main", mouth=None, nose=None),
              horns=dict(color="sub", len=.4, out=.5, fwd=-.1, r=.06), ears=dict(size=(.18, .05, .3), tilt=40, color="main", inner="belly")),
    face=dict(eyes="slit", brow=True),
    wings=dict(kind="bat", span=1.3, chord=.8, angle=55, color="wing", rim="sub"),
    tail=dict(n=5, len=1.0, w=.2, a0=-10, curve=20, tip="blade", tipcolor="sub"),
)

# 18 - ice lion
SPECS[18] = dict(
    slug="ice_lion", kind="quad",
    pal=dict(main=(235, 235, 228), sub=(150, 200, 235), belly=(240, 235, 220), accent=(200, 175, 110), eye=(60, 160, 230)),
    body=(.55, 1.0, .55), leg=.38, legw=.19, neck=(0, .1), sock="sub", paw="sub", claws=True,
    head=dict(size=(.55, .5, .46), ears=dict(size=(.16, .06, .14), kind="up", tilt=10, taper=.8, inner="sub"),
              snout=dict(size=(.24, .25, .17), color="belly", nose="black"), mane=dict(color="sub", n=11, len=.4, r=.14)),
    face=dict(eyes="angry", brow=True, size=1.0),
    tail=dict(n=4, len=.9, w=.1, w1=.1, a0=10, curve=22, tip="fan", tipcolor="sub"), patches=[("accent", -.1, .1, .25, .1)],
)

# 19 - wooden fox with sword
def x19(B, A, p, c):
    B.box((0, -.95, c["hc"].z - .15), (.07, 1.0, .12), "accent")
    B.box((0, -1.5, c["hc"].z - .15), (.2, .12, .22), "main")


SPECS[19] = dict(
    slug="wood_fox_sword", kind="quad",
    pal=dict(main=(190, 130, 50), sub=(40, 60, 90), belly=(215, 165, 85), accent=(225, 170, 60), eye=(60, 110, 170)),
    body=(.5, .95, .5), leg=.38, legw=.14, neck=(0, .15), sock="accent", paw="sub", claws=True,
    head=dict(size=(.48, .45, .4), ears=dict(size=(.18, .06, .5), tilt=6, taper=.25, inner="sub"),
              snout=dict(size=(.2, .4, .15), color="belly", nose="black", mouth=None), mane=dict(color="main", n=7, len=.25, r=.1)),
    face=dict(eyes="angry", brow=True),
    wings=dict(kind="feather", span=.8, n=4, angle=50, color="sub", rim="main", chord=.5),
    tail=dict(n=3, len=.6, w=.32, w1=.2, a0=25, curve=8, tip="fan", tipcolor="main"), extra=x19,
    patches=[("sub", 0, 0, .3, .3)],
)

# 20 - green sky serpent
SPECS[20] = dict(
    slug="sky_serpent", kind="serpent",
    pal=dict(main=(50, 150, 70), sub=(236, 220, 170), accent=(60, 190, 170), eye=(240, 190, 30)),
    path=[(0, 0, 1.7, .2), (0, .3, 1.4, .22), (0, .5, 1.0, .22), (0, .35, .6, .2), (0, -.1, .4, .19), (0, -.5, .55, .17),
          (0, -.65, 1.0, .14), (0, -.35, 1.25, .1), (0, .0, 1.1, .07)],
    n=3, bands="sub", flat=.95,
    head=dict(size=(.4, .5, .3), snout=dict(size=(.25, .35, .15), color="main", mouth="fangs", nose=None),
              horns=dict(color="accent", len=.55, fwd=-.4, out=.5, r=.05)),
    face=dict(eyes="slit"), tailfin=(.4, .4), fins=[(2, "accent", .3, .25), (5, "accent", .3, .25)],
)

# 21 - gator-dragon with blade arms
def x21(B, A, p, c):
    for sx in (1, -1):
        spike(B, (sx * (c["tw"] / 2 + .25), c["sh"].y, c["sh"].z - .15), (sx * .3, -.6, -.7), .9, .16, "accent")


SPECS[21] = dict(
    slug="gator_blade", kind="biped",
    pal=dict(main=(70, 100, 65), sub=(40, 50, 75), belly=(215, 150, 70), accent=(225, 220, 195), eye=(240, 200, 40)),
    legs=(.4, .4), limb=.2, torso=(.6, .45, .55), pelvis=(.5, .4, .24), lean=18, arm=(.3, .3), arm_color="sub", leg_color="sub", pads="sub",
    head=dict(size=(.44, .5, .36), snout=dict(size=(.28, .5, .2), color="main", mouth="fangs", nose=None, dz=-.1), crest=dict(n=3, color="sub", len=.25)),
    face=dict(eyes="slit", brow=True), neck=(.1, .1),
    tail=dict(n=5, len=1.0, w=.28, a0=-5, curve=9, color="main", tip="blade", tipcolor="sub"), spines=dict(n=5, color="belly", len=.2),
    wings=dict(kind="bat", span=.9, chord=.5, angle=50, color="sub", rim="main"), extra=x21,
)

# 22 - ice goodra
def x22(B, A, p, c):
    sh = c["sh"]
    y = sh.y + c["td"] / 2 + .2
    B.box((0, y, sh.z - .3), (.7, .6, .35), "sub", top=(.8, .8))
    B.box((0, y, sh.z - .05), (.55, .5, .25), "accent", top=(.7, .7))
    B.box((0, y, sh.z + .15), (.38, .35, .2), "white", top=(.6, .6))


SPECS[22] = dict(
    slug="ice_goodra", kind="biped",
    pal=dict(main=(185, 175, 225), sub=(160, 210, 240), belly=(245, 240, 235), accent=(215, 190, 130), eye=(70, 160, 100)),
    legs=(.2, .2), limb=.24, torso=(.8, .6, .75), pelvis=(.7, .55, .3), arm=(.3, .3), hand=.22, claws=False, foot_color="belly", pads="sub",
    neck=(0, .35),
    head=dict(size=(.46, .46, .4), snout=dict(size=(.22, .25, .15), color="belly", mouth="smile", nose=None),
              horns=dict(color="sub", len=.45, out=.6, fwd=0, r=.08)),
    face=dict(eyes="cute", size=1.1, mouth=None),
    tail=dict(n=4, len=.8, w=.3, a0=0, curve=18, tip="ball", tipcolor="sub"), extra=x22,
)

# 23 - black/blue shark dragon
SPECS[23] = dict(
    slug="black_blue_dragon", kind="biped",
    pal=dict(main=(25, 28, 40), sub=(30, 80, 200), belly=(30, 80, 200), accent=(120, 190, 255), eye=(240, 170, 40), wing=(30, 40, 70)),
    legs=(.42, .4), limb=.2, torso=(.6, .42, .58), pelvis=(.5, .38, .24), lean=14, pads="sub", arm=(.32, .32), hand=.26, foot_color="main",
    head=dict(size=(.44, .5, .36), snout=dict(size=(.26, .5, .18), color="main", mouth="fangs", nose=None, dz=-.1),
              crest=dict(n=3, color="accent", len=.2)),
    face=dict(eyes="slit", brow=True), neck=(.1, .1),
    wings=dict(kind="bat", span=1.2, chord=.7, angle=50, color="wing", rim="main"),
    tail=dict(n=5, len=1.0, w=.28, a0=-5, curve=9, color="main", tip="tuft", tipcolor="accent"), spines=dict(n=5, color="accent", len=.22),
)

# 24 - white coffee dragon
def x24(B, A, p, c):
    latte(B, A, p, c["hc"] + V((0, .1, .28)), (.3, .3, .16), cup="belly")


SPECS[24] = dict(
    slug="latte_dragon", kind="quad",
    pal=dict(main=(245, 238, 225), sub=(225, 175, 120), belly=(250, 245, 235), accent=(225, 175, 120), eye=(120, 190, 230)),
    body=(.55, 1.0, .5), leg=.4, legw=.15, neck=(.15, .55), claws=True, paw="belly",
    head=dict(size=(.38, .44, .34), snout=dict(size=(.2, .3, .14), color="main", mouth=None, nose=None),
              horns=dict(color="sub", len=.35, out=.5, fwd=-.1, r=.06)),
    face=dict(eyes="cute", size=1.0),
    wings=dict(kind="feather", span=1.0, n=5, angle=45, color="main", rim="sub", chord=.5),
    tail=dict(n=4, len=.9, w=.2, a0=0, curve=14, tip="tuft", tipcolor="sub"), extra=x24,
)
