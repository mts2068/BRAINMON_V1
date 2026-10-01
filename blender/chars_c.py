"""Specs 49-72"""
from cbase import *  # noqa: F403

# 49 - moon lion
SPECS[49] = dict(
    slug="moon_lion", kind="quad",
    pal=dict(main=(215, 205, 180), sub=(60, 80, 140), belly=(225, 215, 190), accent=(60, 80, 140), eye=(60, 150, 230)),
    body=(.55, 1.0, .55), leg=.38, legw=.19, neck=(0, .1), claws=True, paw="sub", sock="sub",
    head=dict(size=(.55, .5, .46), ears=dict(size=(.16, .06, .16), taper=.7, inner="sub"),
              snout=dict(size=(.24, .25, .17), color="belly", nose="black"), mane=dict(color="sub", n=11, len=.38, r=.14),
              horns=dict(color="belly", len=.55, out=0, fwd=-.25, r=.07, x=0)),
    face=dict(eyes="angry", brow=True), patches=[("sub", 0, .05, .2, .2)],
    tail=dict(n=5, len=1.0, w=.1, a0=20, curve=18, color="main", color2="sub", tip="blade", tipcolor="sub"),
)

# 50 - robot dog
SPECS[50] = dict(
    slug="robot_dog", kind="quad",
    pal=dict(main=(225, 215, 190), sub=(70, 170, 160), belly=(225, 215, 190), accent=(70, 170, 160), eye=(230, 170, 40)),
    body=(.55, .9, .5), leg=.35, legw=.18, neck=(0, .1), sock="sub", paw="sub", stripes=("sub", 2, .06),
    head=dict(size=(.55, .5, .46), ears=dict(size=(.18, .06, .3), tilt=10, taper=.5, inner="sub"),
              snout=dict(size=(.2, .2, .15), color="belly", nose="sub", mouth=None)),
    face=dict(eyes="cute", size=1.3), tail=dict(n=1, len=.3, w=.16, a0=20, tip="blade", tipcolor="sub"),
    extra=lambda B, A, p, c: (B.box((0, .0, c["top"] + .15), (.26, .26, .26), "belly"), B.box((0, -.14, c["top"] + .17), (.18, .02, .1), "black")),
)

# 51 - blue/white feathered serpent
SPECS[51] = dict(
    slug="feather_serpent", kind="serpent",
    pal=dict(main=(70, 120, 170), sub=(235, 230, 225), accent=(110, 90, 190), eye=(220, 170, 40), ice=(170, 210, 240)),
    path=[(0, 0, 1.5, .2), (0, .3, 1.25, .22), (0, .4, .9, .22), (0, .2, .55, .2), (0, -.2, .4, .19), (0, -.5, .55, .17),
          (0, -.55, .85, .14), (0, -.3, 1.0, .1), (0, -.05, .9, .07)],
    n=3, bands="sub", flat=.95,
    head=dict(size=(.4, .48, .32), beak=dict(size=(.2, .3, .15), color="accent"), crest=dict(n=6, color="ice", len=.45)),
    face=dict(eyes="slit"), tailfin=(.5, .5), tailfin_color="ice",
    wings=dict(kind="feather", span=.55, n=4, angle=40, color="main", rim="accent", chord=.4),
)

# 52 - pink ribbon fox
def x52(B, A, p, c):
    for sx in (1, -1):
        chain(B, c["hc"] + V((0, 0, -.1)), -20, 12, 5, .22, .07, .05, "belly", "accent", x=sx * .32)


SPECS[52] = dict(
    slug="pink_ribbon_fox", kind="quad",
    pal=dict(main=(240, 140, 160), sub=(250, 245, 245), belly=(250, 245, 245), accent=(100, 190, 240), eye=(70, 160, 240)),
    body=(.4, .6, .4), leg=.35, legw=.13, neck=(0, .15), sock="main", paw="main",
    head=dict(size=(.6, .5, .5), ears=dict(size=(.16, .07, .5), tilt=6, taper=.6, color="main", inner="accent")),
    face=dict(eyes="cute", size=1.3, cheek="sub", mouth="smile"),
    tail=dict(n=3, len=.5, w=.14, a0=-10, curve=20, color="sub", tip="tuft", tipcolor="accent"), extra=x52,
)

# 53 - lilac slender fox with gem
SPECS[53] = dict(
    slug="lilac_gem_cat", kind="quad",
    pal=dict(main=(185, 150, 215), sub=(70, 140, 60), belly=(235, 215, 150), accent=(190, 60, 200), eye=(150, 60, 190)),
    body=(.4, .75, .4), leg=.5, legw=.1, neck=(0, .35), paw="main",
    head=dict(size=(.45, .42, .4), ears=dict(size=(.22, .06, .55), tilt=14, taper=.3, inner="belly"), snout=dict(size=(.16, .2, .12), color="belly", nose="black", mouth=None)),
    face=dict(eyes="cute", size=1.1, mouth=None),
    tail=dict(n=4, len=.8, w=.1, a0=20, curve=14, color="sub", tip="ball", tipcolor="accent"),
    extra=lambda B, A, p, c: B.box(c["hc"] + V((0, -.22, .12)), (.1, .04, .1), "accent"),
)

# 54 - avocado deer, leaf crest
SPECS[54] = dict(
    slug="avocado_deer_2", kind="quad",
    pal=dict(main=(160, 190, 70), sub=(70, 150, 50), belly=(235, 225, 150), accent=(150, 95, 40), eye=(20, 20, 24)),
    body=(.5, .85, .5), leg=.38, legw=.14, neck=(0, .2), paw="accent", sock="main",
    head=dict(size=(.46, .44, .42), snout=dict(size=(.2, .22, .16), color="belly", nose="accent", mouth=None),
              crest=dict(n=6, color="sub", len=.5, r=.14), horns=dict(color="accent", len=.22, r=.05, out=.2)),
    face=dict(eyes="pixel", size=1.0),
    tail=dict(n=2, len=.3, w=.14, a0=40, curve=10, tip="tuft", tipcolor="sub"),
    patches=[("sub", 0, .02, .4, .42), ("accent", 0, -.02, .14, .16)],
)

# 55 - ice lion 2
SPECS[55] = dict(
    slug="ice_lion_2", kind="quad",
    pal=dict(main=(165, 205, 235), sub=(240, 238, 228), belly=(240, 238, 228), accent=(210, 185, 130), eye=(60, 160, 230), ice=(190, 225, 248)),
    body=(.6, 1.1, .55), leg=.4, legw=.2, neck=(0, .3), sock="accent", paw="sub", claws=True,
    head=dict(size=(.5, .5, .42), ears=dict(size=(.16, .06, .16), taper=.8, inner="sub", color="main"),
              snout=dict(size=(.22, .22, .15), color="belly", nose="black"), crest=dict(n=5, color="ice", len=.45)),
    face=dict(eyes="angry", brow=True, size=1.0),
    tail=dict(n=3, len=.5, w=.12, a0=10, curve=15, tip="fan", tipcolor="main", fan=.55),
    extra=lambda B, A, p, c: (B.box((0, .05, c["top"] + .2), (.44, .44, .4), "accent", top=(.6, .6)), B.box((0, .05, c["top"] + .42), (.32, .32, .1), "white")),
)

# 56 - banana dolphin
SPECS[56] = dict(
    slug="banana_dolphin", kind="fish",
    pal=dict(main=(245, 215, 40), sub=(240, 225, 150), belly=(240, 225, 150), accent=(120, 160, 40), eye=(20, 20, 24)),
    body=(.6, 1.2, .6), z=.6, fin="main", face=dict(mouth="smile"),
    extra=lambda B, A, p, c: (B.box((0, 0, c["top"] + .1), (.1, .1, .2), "accent"), B.box((0, -.72, .52), (.3, .3, .22), "main")),
)

# 57 - orange/blue wooden dragon
SPECS[57] = dict(
    slug="wood_dragon", kind="quad",
    pal=dict(main=(225, 140, 50), sub=(50, 110, 150), belly=(240, 215, 160), accent=(150, 175, 70), eye=(70, 130, 170)),
    body=(.55, 1.0, .5), leg=.4, legw=.15, neck=(.1, .4), claws=True, sock="sub", paw="belly",
    head=dict(size=(.42, .46, .38), snout=dict(size=(.2, .3, .14), color="main", mouth=None, nose=None), crest=dict(n=5, color="sub", len=.3),
              horns=dict(color="accent", len=.25, out=.3)),
    face=dict(eyes="slit", brow=True),
    wings=dict(kind="feather", span=1.0, n=5, angle=45, color="belly", rim="main", chord=.6),
    tail=dict(n=5, len=1.0, w=.2, a0=0, curve=6, tip="tuft", tipcolor="sub"), spines=dict(n=5, color="sub", len=.2),
)

# 58 - chocolate lolita girl
def x58(B, A, p, c):
    hc, hz = c["hc"], c["hip_z"]
    B.box(hc + V((0, .08, .02)), (.62, .5, .55), "sub")
    B.box(hc + V((0, -.23, .16)), (.5, .04, .14), "sub")
    for sx in (1, -1):
        B.box(hc + V((sx * .32, .05, .3)), (.22, .22, .22), "sub")
    skirt(B, hz - .02, 1.0, .16, "sub", 1, .5)
    skirt(B, hz - .08, 1.05, .06, "belly", 1, 1)
    skirt(B, hz - .13, 1.1, .06, "green", 1, 1)
    B.box((0, c["sh"].y - c["td"] / 2 - .02, c["sh"].z - .12), (.1, .04, .1), "accent")


SPECS[58] = dict(
    slug="choco_lolita", kind="biped",
    pal=dict(main=(240, 205, 175), sub=(115, 60, 30), belly=(240, 230, 205), accent=(190, 40, 50), eye=(120, 60, 30), green=(110, 160, 60)),
    legs=(.5, .45), limb=.1, torso=(.32, .22, .4), pelvis=(.34, .24, .14), arm=(.3, .28), hand=.12, claws=False, foot_color="sub",
    belly_plate=False, torso_color="sub", pads="sub", head=dict(size=(.5, .45, .45)),
    face=dict(eyes="cute", size=1.1, mouth="smile", cheek="accent"), neck=(0, .05), extra=x58,
)

# 59 - voxel whale
def x59(B, A, p, c):
    for i, j in ((-1, -2), (0, 1), (1, -1), (-1, 2), (0, -3), (1, 3), (-1, 0)):
        B.box((i * .2, j * .17 + .1, c["top"] - .03), (.2, .2, .08), "sub")


SPECS[59] = dict(
    slug="voxel_whale", kind="fish",
    pal=dict(main=(240, 245, 250), sub=(160, 200, 235), belly=(240, 245, 250), accent=(160, 200, 235), eye=(20, 20, 24)),
    body=(.9, 1.3, .7), z=.45, fin="sub", face=dict(mouth="smile"), extra=x59,
)


# 60 - witch cauldron house
def x60(B, A, p, c):
    B.box((0, 0, .08), (1.9, 1.9, .16), "sub")
    for x, y, h in ((-.8, -.7, .2), (.85, -.8, .3), (-.9, .5, .25), (.8, .6, .22)):
        B.box((x, y, .2 + h / 2), (.25, .25, h), "main")
    r = A.region("cf", 300, 260)
    r.fill(S(*p["main"]))
    for x in (.27, .73):
        r.ellipse(300 * x, 175, 38, 38, S(*p["belly"]))
        r.rect(300 * x - 3, 140, 300 * x + 3, 210, S(*p["sub"]))
        r.rect(300 * x - 36, 172, 300 * x + 36, 178, S(*p["sub"]))
    r.ellipse(150, 70, 100, 45, S(*p["red"]))
    r.ellipse(150, 60, 85, 30, S(*p["belly"]))
    for k in range(7):
        xx = 62 + k * 29
        r.rect(xx - 7, 95, xx + 7, 112, S(235, 235, 225))
    B.box((0, 0, .72), (1.2, 1.1, .9), "main", faces={"-y": "cf"}, top=(.88, .88))
    B.box((0, 0, 1.2), (1.0, .9, .12), "sub")
    B.box((0, 0, 1.3), (.45, .1, .14), "red")
    for k in range(7):
        a = k * 0.9
        spike(B, (math.cos(a) * .45, math.sin(a) * .4 + .1, 1.25), (0, 0, 1), .45 + (k % 3) * .15, .1, "sub")
    for sx in (1, -1):
        B.seg((sx * .55, 0, 1.25), (sx * .8, 0, 1.6), .05, .05, "sub")
        B.box((sx * .8, 0, 1.45), (.18, .18, .26), "belly")
        B.box((sx * .9, -.5, .45), (.3, .3, .3), "accent", top=(.6, .6))  # ghost wisp


SPECS[60] = dict(
    slug="witch_cauldron", kind="custom",
    pal=dict(main=(70, 48, 95), sub=(36, 30, 48), belly=(255, 170, 40), accent=(160, 80, 230), red=(190, 50, 60)), extra=x60,
)

# 61 - pink voxel cat
SPECS[61] = dict(
    slug="pink_cat", kind="quad",
    pal=dict(main=(240, 130, 170), sub=(250, 225, 200), belly=(250, 225, 200), accent=(90, 180, 235), eye=(70, 170, 240)),
    body=(.4, .7, .4), leg=.45, legw=.12, neck=(0, .1), paw="main",
    head=dict(size=(.7, .55, .6), ears=dict(size=(.2, .06, .3), tilt=8, taper=.3, inner="sub")),
    face=dict(eyes="cute", size=1.6, mouth="smile", ey=.55, lower="sub"),
    tail=dict(n=7, len=1.2, w=.08, w1=.06, a0=30, curve=15, color="main", color2="accent"),
)


# 62 - electric temple diorama
def x62(B, A, p, c):
    for i in range(6):
        for j in range(6):
            B.box((-.75 + i * .3, -.75 + j * .3, .08), (.3, .3, .16), "main" if (i + j) % 2 == 0 else "sub")
    B.box((0, 0, .42), (.7, .7, .5), "belly")
    B.box((0, 0, .75), (.82, .82, .14), "main", top=(.8, .8))
    B.box((0, -.36, .35), (.2, .04, .3), "sub")
    for sx in (1, -1):
        for sy in (1, -1):
            B.box((sx * .75, sy * .75, .3), (.12, .12, .4), "sub")
            B.box((sx * .75, sy * .75, .53), (.2, .2, .1), "main")
    pts = [(0, 0, .9), (.2, 0, 1.2), (-.1, 0, 1.4), (.15, 0, 1.7), (-.05, 0, 2.0), (.2, 0, 2.3)]
    for a, b in zip(pts, pts[1:]):
        B.seg(a, b, .12, .12, "accent")


SPECS[62] = dict(
    slug="thunder_temple", kind="custom",
    pal=dict(main=(240, 200, 40), sub=(25, 25, 30), belly=(235, 215, 170), accent=(255, 245, 110)), extra=x62,
)

# 63 - orange stegosaurus bread
SPECS[63] = dict(
    slug="bread_stego", kind="quad",
    pal=dict(main=(235, 140, 40), sub=(240, 225, 170), belly=(235, 140, 40), accent=(30, 140, 130), eye=(20, 20, 24)),
    body=(.8, 1.1, .55), leg=.25, legw=.24, neck=(.1, 0), paw="black", chest=False,
    head=dict(size=(.62, .55, .5), snout=dict(size=(.45, .3, .3), color="main", mouth="smile", nose="black", dz=-.1), horns=dict(color="sub", len=.15, r=.07, out=.2)),
    face=dict(eyes="pixel", size=1.3),
    shell=dict(size=(.75, .9, .3), color="sub", lines="accent"), spines=dict(n=5, color="main", len=.4, r=.14),
    tail=dict(n=4, len=.9, w=.22, a0=20, curve=18, color="accent", tip="tuft", tipcolor="main"),
)

# 64 - voxel lion cub
SPECS[64] = dict(
    slug="lion_cub", kind="quad",
    pal=dict(main=(205, 160, 100), sub=(240, 220, 155), belly=(240, 220, 155), accent=(150, 95, 55), eye=(20, 20, 24)),
    body=(.5, .7, .45), leg=.3, legw=.16, neck=(0, .05), paw="sub",
    head=dict(size=(.7, .6, .55), ears=dict(size=(.2, .08, .18), taper=.9, color="accent", inner="sub"),
              snout=dict(size=(.25, .15, .15), color="sub", nose="accent"), mane=dict(color="sub", n=9, len=.28, r=.14)),
    face=dict(eyes="dot", size=1.6, mouth="smile", ey=.58), patches=[("accent", 0, .05, .2, .2)],
    tail=dict(n=4, len=.7, w=.08, a0=25, curve=12, color="accent", tip="tuft", tipcolor="accent"),
)


# 65 - purple lab chamber
def x65(B, A, p, c):
    B.box((0, 0, .06), (2.0, 1.7, .12), "sub")
    B.box((0, .8, .75), (2.0, .12, 1.5), "main")
    B.box((-.95, 0, .75), (.12, 1.7, 1.5), "main")
    B.box((.2, .74, .85), (.5, .04, .5), "sub")
    B.box((-.4, .2, .72), (.7, .7, 1.2), "glass")
    B.box((-.4, .2, .14), (.8, .8, .16), "main")
    B.box((-.4, .2, 1.4), (.8, .8, .16), "main")
    B.box((.45, -.2, .35), (.55, .55, .6), "main")
    B.box((.45, -.2, .66), (.62, .62, .06), "dark")
    B.box((.45, -.52, .4), (.5, .05, .75), "dark", rot=(-8, 0, 0))


SPECS[65] = dict(
    slug="lab_chamber", kind="custom",
    pal=dict(main=(150, 150, 162), sub=(110, 80, 190), accent=(190, 160, 255), glass=(180, 165, 235), dark=(105, 105, 118)), extra=x65,
)

# 66 - purple crystal godzilla
SPECS[66] = dict(
    slug="crystal_zilla", kind="biped",
    pal=dict(main=(110, 135, 100), sub=(150, 150, 130), belly=(150, 160, 130), accent=(150, 90, 220), eye=(240, 220, 60)),
    legs=(.4, .4), limb=.24, torso=(.68, .45, .62), pelvis=(.55, .4, .26), lean=14, pads="sub", arm=(.35, .35), hand=.3, foot_color="sub",
    head=dict(size=(.46, .5, .38), snout=dict(size=(.3, .45, .2), color="main", mouth="fangs", nose=None, dz=-.1), crest=dict(n=3, color="sub", len=.25)),
    face=dict(eyes="slit", brow=True), neck=(.1, .1), spines=dict(n=6, color="accent", len=.5, r=.09),
    tail=dict(n=5, len=1.0, w=.3, a0=-5, curve=9, tip="blade", tipcolor="accent"),
    extra=lambda B, A, p, c: B.box((c["sh"].x, c["sh"].y - c["td"] / 2 - .03, c["sh"].z - .22), (.28, .05, .28), "accent"),
)

# 67 - green wooden hammerhead serpent
SPECS[67] = dict(
    slug="wood_serpent", kind="serpent",
    pal=dict(main=(100, 125, 50), sub=(185, 150, 90), accent=(110, 80, 40), eye=(240, 210, 50)),
    path=[(0, 0, 1.4, .22), (0, .3, 1.2, .24), (0, .4, .85, .24), (0, .2, .5, .22), (0, -.2, .35, .2), (0, -.55, .5, .18),
          (0, -.6, .85, .15), (0, -.3, 1.0, .11), (0, 0, .85, .08)],
    n=3, bands="sub", flat=.9, head=dict(size=(1.0, .42, .26), snout=None, horns=dict(color="accent", len=.3, out=.6, fwd=0, x=.45)),
    face=dict(eyes="slit", sep=.1), tailfin=(.45, .6), tailfin_color="accent", fins=[(3, "accent", .35, .3), (5, "accent", .35, .3)],
)


# 68 - patchwork jester
def x68(B, A, p, c):
    B.box((0, 0, .05), (1.2, 1.2, .1), "main")
    chain(B, c["hc"] + V((0, 0, .15)), 80, -22, 4, .22, .38, .1, "main", "sub")
    chain(B, c["hc"] + V((0, -.05, .1)), 60, 20, 3, .2, .3, .1, "belly", flip=-1)
    B.box((0, -.3, c["zc"] - .05), (.1, .06, .12), "accent")


SPECS[68] = dict(
    slug="jester_patch", kind="blob", no_feet=True,
    pal=dict(main=(130, 70, 170), sub=(230, 90, 150), belly=(110, 130, 220), accent=(135, 110, 70), eye=(20, 20, 24), skin=(230, 190, 155)),
    body=(.8, .7, .75), lift=.1, body_top=(.55, .55), body_bot=(1, 1), chest=False,
    head=dict(size=(.42, .4, .38), color="skin"), face=dict(base="skin", eyes="dot", size=1.4, mouth="smile"), extra=x68,
)


# 69 - hermit crab
def x69(B, A, p, c):
    legs6(B, .45, c["bw"], (-.25, .05, .35), "main", reach=.5)
    for sx in (1, -1):
        B.seg((sx * .4, -.3, c["zc"]), (sx * .55, -.75, c["zc"] - .05), .2, .2, "sub")
        B.box((sx * .55, -.9, c["zc"] - .05), (.3, .35, .3), "sub")
        spike(B, (sx * .6, -1.0, c["zc"] - .02), (-sx * .3, -1, 0), .4, .1, "main")
        spike(B, (sx * .45, -1.0, c["zc"] - .02), (sx * .3, -1, 0), .4, .1, "main")


SPECS[69] = dict(
    slug="hermit_crab", kind="blob", no_feet=True,
    pal=dict(main=(190, 130, 60), sub=(205, 185, 140), belly=(190, 130, 60), accent=(190, 130, 60), eye=(40, 30, 20)),
    body=(.9, .9, .6), lift=.45, body_color="sub", chest=False, body_top=(.9, .9),
    head=dict(size=(.5, .42, .4), color="main", horns=dict(color="accent", len=.2, out=.1, fwd=0, r=.05)),
    face=dict(eyes="cute", size=1.3, mouth="smile"), extra=x69,
)

# 70 - mermaid
def x70(B, A, p, c):
    hc = c["hc"]
    B.box(hc + V((0, .15, -.3)), (.62, .3, .9), "sub")
    B.box(hc + V((0, .0, .15)), (.56, .5, .16), "sub")
    B.box((0, c["sh"].y - c["td"] / 2 - .02, c["sh"].z - .1), (.34, .05, .14), "sub")


SPECS[70] = dict(
    slug="mermaid", kind="biped", no_legs=True, hip=.8,
    pal=dict(main=(240, 205, 175), sub=(120, 215, 200), belly=(240, 205, 175), accent=(235, 245, 230), eye=(60, 170, 120)),
    torso=(.34, .22, .4), pelvis=(.36, .24, .16), arm=(.3, .3), hand=.12, limb=.1, claws=False, belly_plate=False,
    head=dict(size=(.5, .45, .45)), face=dict(eyes="cute", size=1.1, mouth="smile"), neck=(0, .05),
    tail=dict(n=5, len=1.1, w=.32, w1=.12, a0=-100, curve=14, color="sub", color2="accent", tip="fan", tipcolor="sub", fan=.6), extra=x70,
)

# 71 - mantis bug with claws
SPECS[71] = dict(
    slug="mantis_fairy", kind="biped",
    pal=dict(main=(150, 215, 150), sub=(70, 170, 170), belly=(235, 235, 200), accent=(220, 120, 60), eye=(130, 70, 40), wing=(190, 235, 190)),
    legs=(.4, .4), limb=.1, torso=(.35, .25, .4), pelvis=(.32, .24, .15), arm=(.3, .3), hand=.45, hand_color="accent", claws=False, foot_color="sub",
    belly_plate=False, torso_color="sub",
    head=dict(size=(.55, .5, .5), horns=dict(color="accent", len=.35, out=.2, fwd=0, r=.04)),
    face=dict(eyes="cute", size=1.4, mouth="smile"),
    wings=dict(kind="butterfly", span=.7, chord=.55, angle=40, color="wing", rim="main"), neck=(0, .05),
)

# 72 - eye totem with sword & shield
def x72(B, A, p, c):
    r = A.region("eye", 160, 160)
    r.fill(S(*p["main"]))
    r.ellipse(80, 80, 62, 42, S(255, 255, 255))
    r.ellipse(80, 80, 28, 28, S(*p["eye"]))
    r.ellipse(80, 80, 12, 12, S(*p["black"]))
    r2 = A.region("diamond", 128, 160)
    r2.fill(S(*p["accent"]))
    r2.ellipse(64, 80, 40, 56, S(*p["sub"]))
    r2.ellipse(64, 80, 20, 28, S(*p["belly"]))
    B.box((0, 0, .6), (.55, .4, 1.0), "sub", top=(1.1, 1.0), bot=(.6, .7))
    B.box((0, -.2, .75), (.6, .05, .5), "accent")
    B.box((0, 0, 1.4), (.5, .42, .5), "main", faces={"-y": "eye"})
    spike(B, (0, 0, 1.65), (0, 0, 1), .4, .12, "sub")
    for sx in (1, -1):
        spike(B, (sx * .25, 0, 1.55), (sx, 0, 1), .25, .07, "belly")
    B.box((-.8, -.05, .95), (.12, .06, 1.5), "belly")
    B.box((-.8, -.05, 1.8), (.1, .06, .2), "sub", top=(.1, 1))
    B.box((-.8, -.05, .2), (.3, .08, .08), "sub")
    B.box((.75, -.1, .85), (.7, .1, 1.0), "accent", faces={"-y": "diamond"}, bot=(.3, 1), top=(1, 1))


SPECS[72] = dict(
    slug="eye_totem", kind="custom",
    pal=dict(main=(215, 185, 140), sub=(60, 160, 170), belly=(235, 220, 190), accent=(220, 120, 110), eye=(60, 170, 190)), extra=x72,
)
