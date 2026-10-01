"""Brainmon 01 - blue/black dog warrior (ref: refs 1.png). blender -b --python blender/brainmon_01.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy  # noqa: E402
import bm_lib as L  # noqa: E402

OUT = os.path.join(HERE, "..", "assets", "brainmon", "01_dog_warrior")
os.makedirs(OUT, exist_ok=True)
OUT = os.path.abspath(OUT)
bpy.ops.wm.read_factory_settings(use_empty=True)

A = L.Atlas()
C = dict(blue=(32, 78, 190), blue2=(22, 56, 140), black=(24, 24, 28), cream=(226, 206, 166),
         cream2=(170, 146, 108), red=(176, 36, 32), orange=(196, 124, 46), brown=(104, 62, 26),
         claw=(14, 14, 16), eyeblue=(40, 120, 230))
for k, v in C.items():
    A.color(k, v)
S = L.srgb
BLUE, BLACK, CREAM, CREAM2, RED = S(*C["blue"]), S(*C["black"]), S(*C["cream"]), S(*C["cream2"]), S(*C["red"])

# ---- painted regions (512 px per metre) ----
# head front: blue left / black right, cream blaze, angry blue eye (left), cream spiral on black patch (right)
r = A.region("head_front", 307, 256)
W, H = r.w, r.h
r.fill(BLUE, r.X < W / 2)
r.fill(BLACK, r.X >= W / 2)
r.bricks(12, 12, S(*C["blue2"]), r.X < W / 2)
r.fill(CREAM, (abs(r.X - W / 2) < 30) & (r.Y < H * 0.85))
r.ellipse(W * 0.30, H * 0.68, 38, 19, CREAM)            # eye white
r.ellipse(W * 0.31, H * 0.68, 16, 16, S(*C["eyeblue"]))  # iris
r.ellipse(W * 0.31, H * 0.68, 7, 7, S(8, 12, 30))        # pupil
r.line((W * 0.10, H * 0.84), (W * 0.40, H * 0.74), 10, BLACK)  # angry brow, inner end lower
r.spiral(W * 0.74, H * 0.68, 16, 6, 46, CREAM)           # spiral on the black patch

r = A.region("head_top", 128, 128)
r.fill(BLUE, r.X < 64)
r.fill(BLACK, r.X >= 64)
r = A.region("head_back", 128, 128)
r.fill(BLACK, r.X < 64)  # back view is mirrored: +x (black) is on the left of the uv
r.fill(BLUE, r.X >= 64)

r = A.region("muzzle_front", 143, 102)
r.fill(CREAM)
r.line((20, 30), (72, 20), 6, BLACK)
r.line((72, 20), (124, 30), 6, BLACK)
r.line((72, 20), (72, 46), 5, BLACK)

r = A.region("chest", 195, 174)
r.fill(CREAM)
r.spiral(97, 87, 30, 9, 82, CREAM2)

r = A.region("foot", 143, 82)
r.fill(CREAM)
for x in (36, 72, 108):
    r.line((x, 0), (x, 60), 4, CREAM2)

for nm, rim in (("ear_L", BLUE), ("ear_R", BLACK)):
    r = A.region(nm, 102, 143)
    r.fill(rim)
    r.rect(12, 12, 90, 143, S(*C["orange"]))
    r.spiral(51, 70, 18, 7, 36, S(*C["brown"]))

# ---- model ----
B = L.Builder(A)
box, cone = B.box, B.cone

# legs: blue thigh, cream wrapped shin with red stripe, cream foot with black claws
box((0.18, 0, 0.72), (0.22, 0.24, 0.3), "blue", mirror=True)
box((0.18, -0.12, 0.74), (0.15, 0.1, 0.15), "blue", mirror=True)  # knee block
box((0.18, 0, 0.42), (0.3, 0.3, 0.2), "cream", bot=(1, 1), top=(0.92, 0.92), mirror=True)
box((0.18, 0, 0.32), (0.32, 0.32, 0.06), "red", mirror=True)
box((0.18, 0, 0.24), (0.3, 0.3, 0.14), "cream", mirror=True)
box((0.18, -0.08, 0.08), (0.28, 0.42, 0.16), "cream", faces={"-y": "foot"}, mirror=True)
for sx in (1, -1):
    for dx in (-0.09, -0.03, 0.03, 0.09):
        box((sx * 0.18 + dx, -0.3, 0.03), (0.04, 0.05, 0.04), "claw")
# pelvis, belt, knot
box((0, 0, 0.98), (0.64, 0.4, 0.3), "black", bot=(0.95, 1))
box((0, 0, 1.13), (0.68, 0.44, 0.1), "red")
box((0, -0.24, 1.11), (0.13, 0.07, 0.13), "red")
box((0.06, -0.25, 0.98), (0.08, 0.04, 0.22), "red", rot=(0, 8, 0))
box((-0.06, -0.25, 0.98), (0.08, 0.04, 0.22), "red", rot=(0, -8, 0))
# torso (black gi), spiral chest plate, fur spikes
box((0, 0, 1.42), (0.7, 0.42, 0.5), "black", top=(1.18, 1), bot=(0.88, 1))
box((0, -0.225, 1.43), (0.38, 0.06, 0.34), "cream", faces={"-y": "chest"})
for x, z, rz in ((0, 1.66, 0), (-0.12, 1.64, 25), (0.12, 1.64, -25), (-0.22, 1.6, 50), (0.22, 1.6, -50)):
    cone((x, -0.24, z), 0.07, 0.2, "cream", rot=(-8, rz, 0))
# shoulders & arms: blue pads, black upper arm, blue forearm, striped cream wrist, big blue fist
box((0.5, 0, 1.62), (0.28, 0.36, 0.22), "blue", mirror=True)
box((0.54, 0, 1.4), (0.24, 0.28, 0.32), "black", mirror=True)
box((0.55, 0, 1.14), (0.22, 0.25, 0.26), "blue", mirror=True)
box((0.55, 0, 0.93), (0.3, 0.3, 0.12), "cream", mirror=True)
box((0.55, 0, 0.84), (0.31, 0.31, 0.05), "red", mirror=True)
box((0.55, 0, 0.77), (0.3, 0.3, 0.1), "cream", mirror=True)
box((0.55, -0.02, 0.6), (0.28, 0.32, 0.26), "blue", bot=(0.85, 0.85), mirror=True)
# tail (blue, curls up)
box((0, 0.26, 0.96), (0.13, 0.22, 0.13), "blue", rot=(-30, 0, 0))
box((0, 0.42, 0.86), (0.12, 0.2, 0.12), "blue", rot=(-45, 0, 0))
box((0, 0.56, 0.8), (0.11, 0.2, 0.11), "blue", rot=(-10, 0, 0))
box((0, 0.67, 0.84), (0.1, 0.18, 0.1), "blue", rot=(40, 0, 0))
box((0, 0.73, 0.94), (0.08, 0.16, 0.08), "blue", rot=(70, 0, 0))
# neck + head
box((0, 0, 1.72), (0.3, 0.3, 0.14), "black")
box((0, -0.02, 2.0), (0.6, 0.52, 0.5), "blue",
    faces={"-y": "head_front", "+z": "head_top", "+y": "head_back", "+x": "black", "-x": "blue"})
box((0, -0.43, 1.87), (0.28, 0.36, 0.2), "cream", faces={"-y": "muzzle_front"}, top=(0.9, 0.9))
box((0, -0.6, 1.98), (0.16, 0.1, 0.09), "black")  # nose
box((-0.23, 0.0, 2.43), (0.2, 0.1, 0.28), "blue", faces={"-y": "ear_L"}, rot=(0, -8, 0))
box((0.23, 0.0, 2.43), (0.2, 0.1, 0.28), "black", faces={"-y": "ear_R"}, rot=(0, 8, 0))

obj = B.build("Brainmon_01_DogWarrior", OUT, "tex_01")
L.export(obj, OUT, "brainmon_01")
L.render_views(obj, OUT, "preview")
