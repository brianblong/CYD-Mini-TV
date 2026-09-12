"""Check printable STL topology and dimensions using only Python's standard library."""
from collections import Counter, defaultdict
from pathlib import Path
import json
import math
import struct

ROOT = Path(__file__).resolve().parent
EXPECTED = {
    "housing": (1, (150, 91, 40)),
    "back_cover": (1, (150, 80, 4)),
    "knobs": (2, (37, 16, 10)),
    "antennas": (2, (16.5, 40, 4)),
    "fit_coupon": (1, (45, 32, 8)),
}

def triangles(path):
    data = path.read_bytes()
    if len(data) >= 84:
        count = struct.unpack_from("<I", data, 80)[0]
        if len(data) == 84 + 50 * count:
            for i in range(count):
                f = struct.unpack_from("<12fH", data, 84 + i * 50)
                yield tuple(tuple(f[j:j+3]) for j in (3, 6, 9))
            return
    verts = [tuple(map(float, line.split()[1:])) for line in data.decode().splitlines()
             if line.strip().startswith("vertex ")]
    assert len(verts) % 3 == 0
    for i in range(0, len(verts), 3):
        yield tuple(verts[i:i+3])

def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])

def check(name, expectation):
    tris = list(triangles(ROOT / (name + ".stl")))
    assert tris, name
    edges = Counter()
    directed = Counter()
    adjacent = defaultdict(set)
    volume = 0.0
    degenerate = 0
    for a, b, c in tris:
        normal = cross(tuple(b[i]-a[i] for i in range(3)), tuple(c[i]-a[i] for i in range(3)))
        degenerate += math.sqrt(sum(x*x for x in normal)) < 1e-10
        volume += sum(a[i]*cross(b, c)[i] for i in range(3)) / 6
        for u, v in ((a,b), (b,c), (c,a)):
            edges[tuple(sorted((u,v)))] += 1
            directed[(u,v)] += 1
            adjacent[u].add(v)
            adjacent[v].add(u)
    verts = list(adjacent)
    low = [min(v[i] for v in verts) for i in range(3)]
    high = [max(v[i] for v in verts) for i in range(3)]
    extent = [high[i]-low[i] for i in range(3)]
    remaining = set(verts)
    bodies = 0
    while remaining:
        pending = [remaining.pop()]
        bodies += 1
        while pending:
            for nxt in adjacent[pending.pop()]:
                if nxt in remaining:
                    remaining.remove(nxt)
                    pending.append(nxt)
    assert all(n == 2 for n in edges.values()), f"{name}: open/nonmanifold edge"
    assert all(n == directed[(v,u)] for (u,v),n in directed.items()), f"{name}: winding"
    assert not degenerate, f"{name}: degenerate triangles"
    assert bodies == expectation[0], (name, bodies)
    # Knurl grooves and faceted circles may slightly reduce the bounding box.
    assert all(abs(a-b) < 0.15 for a,b in zip(extent, expectation[1])), (name, extent)
    assert abs(low[2]) < 1e-5, (name, "not on bed", low)
    assert volume > 0, (name, "negative volume")
    return {"part":name,"triangles":len(tris),"closed_manifold":True,
            "connected_bodies":bodies,"extent_mm":[round(x,4) for x in extent],
            "volume_mm3":round(volume,2),"bed_z_mm":low[2]}

if __name__ == "__main__":
    report = [check(name, expected) for name, expected in EXPECTED.items()]
    print(json.dumps(report, indent=2))
