"""Spec registry: ids = number of the reference image. 1 is the hand-built pilot (brainmon_01.py)."""
from cbase import SPECS  # noqa: F401
import chars_a  # noqa: F401
for _m in ("chars_b", "chars_c", "chars_d"):
    try:
        __import__(_m)
    except ModuleNotFoundError as e:
        if e.name != _m:
            raise
