"""Shared helpers for building Brainmon models: blocky parts + one painted texture atlas.

Run inside Blender (headless): blender -b --python blender/brainmon_01.py
Conventions: Z up, character faces -Y, +X is the viewer's right when looking at the front.
Faces of a part are named '+x','-x','+y','-y','+z','-z'. Each face is either a palette colour
(flat swatch) or a painted region of the atlas (the "texture painting" for faces/marks).
"""
import math
import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

ATLAS = 1024
CELL = 32  # swatch cell size; 8 per row, rows at the bottom of the atlas
PAD = 4
BRICK = 0.86  # joint darkness


def srgb(r, g, b):
    return (r / 255, g / 255, b / 255, 1.0)


class Region:
    def __init__(self, atlas, x0, y0, w, h):
        self.atlas, self.x0, self.y0, self.w, self.h = atlas, x0, y0, w, h
        self.px = atlas.px[y0:y0 + h, x0:x0 + w]  # view, row 0 = bottom
        self.Y, self.X = np.mgrid[0:h, 0:w].astype(np.float32)
        self.X += 0.5
        self.Y += 0.5

    def fill(self, color, mask=None):
        if mask is None:
            self.px[:] = color
        else:
            self.px[mask] = color

    def rect(self, x0, y0, x1, y1, color):
        self.fill(color, (self.X >= x0) & (self.X < x1) & (self.Y >= y0) & (self.Y < y1))

    def ellipse(self, cx, cy, rx, ry, color):
        self.fill(color, ((self.X - cx) / rx) ** 2 + ((self.Y - cy) / ry) ** 2 <= 1)

    def line(self, p0, p1, width, color):
        a, b = np.array(p0, np.float32), np.array(p1, np.float32)
        ab = b - a
        t = np.clip(((self.X - a[0]) * ab[0] + (self.Y - a[1]) * ab[1]) / (ab @ ab), 0, 1)
        d = np.hypot(self.X - (a[0] + t * ab[0]), self.Y - (a[1] + t * ab[1]))
        self.fill(color, d <= width / 2)

    def spiral(self, cx, cy, pitch, width, radius, color, cw=1):
        dx, dy = self.X - cx, self.Y - cy
        r, th = np.hypot(dx, dy), np.arctan2(dy, dx) * cw
        d = (r - pitch * th / (2 * np.pi)) % pitch
        self.fill(color, (d < width) & (r < radius))

    def bricks(self, rows, cols, color, mask):
        """thin brick lines on the masked area (the carved-stone look of the references)"""
        bh, bw = self.h / rows, self.w / cols
        row = (self.Y // bh).astype(int)
        hl = (self.Y % bh) < 1.2
        vl = ((self.X + (row % 2) * bw / 2) % bw) < 1.2
        self.fill(color, mask & (hl | vl))


class Atlas:
    def __init__(self):
        self.px = np.ones((ATLAS, ATLAS, 4), np.float32)
        self.colors, self.regions = {}, {}
        self._cx, self._cy, self._rowh = 0, CELL * 8, 0

    def color(self, name, rgb):
        """palette swatch: flat colour with faint brick joints (carved-block look); boxes map their faces onto it"""
        i = len(self.colors)
        assert i < 64, "palette full"
        x, y = (i % 8) * CELL, (i // 8) * CELL
        base = np.array(srgb(*rgb), np.float32)
        cell = np.tile(base, (CELL, CELL, 1))
        dark = base * np.array([BRICK, BRICK, BRICK, 1], np.float32)
        for r in range(4):  # 4 rows of 8px bricks, alternate rows offset by half a brick
            cell[r * 8 + 7, :] = dark
            for vx in ((15, 31) if r % 2 == 0 else (7, 23)):
                cell[r * 8:r * 8 + 8, vx] = dark
        self.px[y:y + CELL, x:x + CELL] = cell
        self.colors[name] = (x + 11.5, y + 11.5)  # collapsed point: inside a brick, away from joints
        self.cells = getattr(self, "cells", {})
        self.cells[name] = (x, y)

    def region(self, name, w, h):
        """allocate a w*h painted region (shelf packing) and return it for drawing"""
        W, H = w + 2 * PAD, h + 2 * PAD
        if self._cx + W > ATLAS:
            self._cx, self._cy, self._rowh = 0, self._cy + self._rowh, 0
        assert self._cy + H <= ATLAS, "atlas full"
        r = Region(self, self._cx + PAD, self._cy + PAD, w, h)
        self._cx += W
        self._rowh = max(self._rowh, H)
        self.regions[name] = r
        return r

    def bleed(self):
        """extend region edges into their padding so filtering never shows seams"""
        for r in self.regions.values():
            ys, xs = slice(r.y0 - PAD, r.y0 + r.h + PAD), slice(r.x0 - PAD, r.x0 + r.w + PAD)
            self.px[ys, xs] = np.pad(r.px, ((PAD, PAD), (PAD, PAD), (0, 0)), mode="edge")

    def uv(self, name, u, v, tile=False):
        """u,v in 0..1 -> atlas uv for a region; palette names collapse to the swatch centre"""
        if name in self.regions:
            r = self.regions[name]
            return ((r.x0 + u * r.w) / ATLAS, (r.y0 + v * r.h) / ATLAS)
        if tile:
            x, y = self.cells[name]
            return ((x + 1 + u * (CELL - 2)) / ATLAS, (y + 1 + v * (CELL - 2)) / ATLAS)
        cx, cy = self.colors[name]
        return (cx / ATLAS, cy / ATLAS)


class Builder:
    def __init__(self, atlas):
        self.atlas, self.bm = atlas, bmesh.new()
        self.uvl = self.bm.loops.layers.uv.new("UVMap")

    def _collapse(self, faces, name):
        for f in faces:
            for l in f.loops:
                l[self.uvl].uv = self.atlas.uv(name, 0, 0)

    def box(self, center, size, color, faces=None, rot=(0, 0, 0), top=(1, 1), bot=(1, 1), mirror=False):
        """Box (optionally tapered: top/bot = (x,y) scale of the top/bottom ring).
        faces: {'-y': region_or_color, ...} overrides `color` per face. mirror=True adds the X-mirrored twin."""
        if mirror:
            m = {"+x": "-x", "-x": "+x"}
            self.box(center, size, color, faces, rot, top, bot)
            self.box((-center[0], center[1], center[2]), size, color,
                     {m.get(k, k): v for k, v in (faces or {}).items()}, (rot[0], -rot[1], -rot[2]), top, bot)
            return
        bm = self.bm
        verts = bmesh.ops.create_cube(bm, size=1.0)["verts"]
        fs = {f for v in verts for f in v.link_faces}
        key = {}
        for f in fs:
            c = f.calc_center_median()
            ax = max(range(3), key=lambda i: abs(c[i]))
            key[f] = ("+" if c[ax] > 0 else "-") + "xyz"[ax]
        for v in verts:
            t = v.co.z + 0.5
            sx = bot[0] + (top[0] - bot[0]) * t
            sy = bot[1] + (top[1] - bot[1]) * t
            v.co = Vector((v.co.x * size[0] * sx, v.co.y * size[1] * sy, v.co.z * size[2]))
        lo = Vector((min(v.co.x for v in verts), min(v.co.y for v in verts), min(v.co.z for v in verts)))
        hi = Vector((max(v.co.x for v in verts), max(v.co.y for v in verts), max(v.co.z for v in verts)))
        n = lambda v, i: (v[i] - lo[i]) / ((hi[i] - lo[i]) or 1)
        for f in fs:
            k = key[f]
            name = (faces or {}).get(k, color)
            for l in f.loops:
                p = l.vert.co
                uv = {"-y": (n(p, 0), n(p, 2)), "+y": (1 - n(p, 0), n(p, 2)),
                      "+x": (n(p, 1), n(p, 2)), "-x": (1 - n(p, 1), n(p, 2)),
                      "+z": (n(p, 0), n(p, 1)), "-z": (n(p, 0), 1 - n(p, 1))}[k]
                l[self.uvl].uv = self.atlas.uv(name, *uv, tile=True)
        mat = Matrix.Translation(center) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
        bmesh.ops.transform(bm, matrix=mat, verts=verts)

    def seg(self, p0, p1, w, d, color, faces=None, t0=1.0, t1=1.0):
        """Box between two points: local Z runs p0->p1, w/d are its cross-section, t0/t1 scale the ends."""
        p0, p1 = Vector(p0), Vector(p1)
        v = p1 - p0
        z = v.normalized()
        xr = Vector((1, 0, 0)) if abs(z.x) < 0.9 else Vector((0, 1, 0))
        y = z.cross(xr).normalized()
        x = y.cross(z)
        e = Matrix((x, y, z)).transposed().to_euler()
        self.box((p0 + p1) / 2, (w, d, v.length), color, faces, rot=tuple(math.degrees(a) for a in e),
                 top=(t1, t1), bot=(t0, t0))

    def cone(self, center, radius, depth, color, rot=(0, 0, 0), segments=4, tip=0.0):
        """spike/pyramid along local Z (tip at +Z)"""
        bm = self.bm
        mat = Matrix.Translation(center) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
        r = bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=tip,
                                  depth=depth, matrix=mat)
        self._collapse({f for v in r["verts"] for f in v.link_faces}, color)

    def build(self, name, outdir, tex_name):
        a = self.atlas
        a.bleed()
        me = bpy.data.meshes.new(name)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        self.bm.to_mesh(me)
        self.bm.free()
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        img = bpy.data.images.new(tex_name, ATLAS, ATLAS, alpha=False)
        img.pixels.foreach_set(a.px.ravel())
        img.filepath_raw = f"{outdir}/{tex_name}.png"
        img.file_format = "PNG"
        img.save()
        img.pack()
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 0.8
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image, tex.interpolation = img, "Closest"
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        me.materials.append(mat)
        return obj


def render_views(obj, outdir, prefix, views=(("front", 0), ("three_quarter", 35), ("side", 90), ("back", 180))):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = 600, 800
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.57, 0.6, 1)
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.2
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-30))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector(map(min, *bb))
    hi = Vector(map(max, *bb))
    ctr, size = (lo + hi) / 2, (hi - lo).length
    for nm, ang in views:
        a = math.radians(ang)
        cam.location = ctr + Vector((math.sin(a), -math.cos(a), 0.08)) * size * 1.45
        cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = f"{outdir}/{prefix}_{nm}.png"
        bpy.ops.render.render(write_still=True)


def add_idle(obj, frames=48, fps=24):
    """Looping 'Idle' on the object: breathing (feet stay planted since the origin is on the ground),
    a slight sway, and a gentle bob for creatures that float. Seamless loop: frame 1 == frame frames+1."""
    sc = bpy.context.scene
    sc.render.fps = fps
    sc.frame_start, sc.frame_end = 1, frames + 1
    floats = min((obj.matrix_world @ Vector(c)).z for c in obj.bound_box) > 0.12
    h = max((obj.matrix_world @ Vector(c)).z for c in obj.bound_box)
    keys = (  # (frame fraction, scale xy, scale z, sway deg, bob)
        (0.0, 1.000, 1.000, -1.2, 0.0),
        (0.25, 0.992, 1.018, 0.0, 0.5),
        (0.5, 0.985, 1.028, 1.2, 1.0),
        (0.75, 0.992, 1.018, 0.0, 0.5),
        (1.0, 1.000, 1.000, -1.2, 0.0),
    )
    for fr, sxy, sz, sway, bob in keys:
        f = 1 + round(fr * frames)
        obj.scale = (sxy, sxy, sz)
        obj.rotation_euler = (0, 0, math.radians(sway))
        obj.location = (0, 0, bob * 0.035 * max(h, 1.0) if floats else 0)
        for path in ("scale", "rotation_euler", "location"):
            obj.keyframe_insert(data_path=path, frame=f)
    obj.animation_data.action.name = "Idle"
    sc.frame_set(1)


def export(obj, outdir, name):
    add_idle(obj)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=f"{outdir}/{name}.glb", use_selection=True, export_format="GLB", export_animations=True)
    bpy.ops.wm.save_as_mainfile(filepath=f"{outdir}/{name}.blend")
    print("TRIS", sum(len(p.vertices) - 2 for p in obj.data.polygons))
