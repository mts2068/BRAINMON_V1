"""Build Brainmon models: blender -b --python blender/run.py -- 8 3 20   (or: -- all)"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy  # noqa: E402
import bm_arch as AR  # noqa: E402
import bm_lib as L  # noqa: E402
import characters  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "assets", "brainmon"))
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["all"]
ids = sorted(characters.SPECS) if args == ["all"] else [int(a) for a in args]
for i in ids:
    s = characters.SPECS[i]
    out = os.path.join(ROOT, f"{i:02d}_{s['slug']}")
    os.makedirs(out, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        obj = AR.build(s, out, f"tex_{i:02d}", f"Brainmon_{i:02d}_{s['slug']}")
        L.export(obj, out, f"brainmon_{i:02d}")
        L.render_views(obj, out, "preview", views=(("three_quarter", 35), ("front", 0)))
        print("OK", i, s["slug"])
    except Exception as e:  # keep going so one bad spec doesn't stop the batch
        import traceback
        traceback.print_exc()
        print("FAIL", i, s["slug"], e)
