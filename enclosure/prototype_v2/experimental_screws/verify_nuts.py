"""Validate nut exports with the existing enclosure topology checker."""
from pathlib import Path
import sys
import json
import math

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
import verify_meshes as mesh

mesh.ROOT = ROOT
width = 5.5 / math.cos(math.radians(30))
if __name__ == '__main__':
    results = [mesh.check('test_nut', (1, (width, 5.5, 2.0))),
               mesh.check('nuts_m3_set_of_8', (8, (width+27, 14.5, 2.0)))]
    print(json.dumps(results, indent=2))
