"""Contact sheet of previews: blender -b --python blender/sheet.py -- OUT.png view id id id ...   (view: three_quarter|front)"""
import glob, os, sys
import bpy, numpy as np
a = sys.argv[sys.argv.index("--") + 1:]
out, view, ids = a[0], a[1], [int(x) for x in a[2:]]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "brainmon")
cw, ch, cols = 300, 400, 4
rows = (len(ids) + cols - 1) // cols
sheet = np.ones((ch * rows, cw * cols, 4), np.float32)
for k, i in enumerate(ids):
    f = glob.glob(os.path.join(root, f"{i:02d}_*", f"preview_{view}.png"))
    if not f:
        continue
    im = bpy.data.images.load(f[0]); im.scale(cw, ch)
    px = np.empty(cw * ch * 4, np.float32); im.pixels.foreach_get(px)
    r, c = divmod(k, cols)
    sheet[(rows - 1 - r) * ch:(rows - r) * ch, c * cw:(c + 1) * cw] = px.reshape(ch, cw, 4)
im = bpy.data.images.new("s", cw * cols, ch * rows); im.pixels.foreach_set(sheet.ravel())
im.filepath_raw = out; im.file_format = "PNG"; im.save()
