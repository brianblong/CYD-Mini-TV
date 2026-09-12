"""Weld numerical CAD-export slivers, then emit compact binary printable STLs.

Only edges shorter than 0.00003 mm may collapse. Thread geometry is not smoothed
or rescaled. Mesh topology and dimensions are checked separately after finishing.
"""
from pathlib import Path
import sys
import math
import struct
import json

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
from verify_meshes import triangles, cross

def finish(name):
    path=ROOT/(name+'.stl')
    source=list(triangles(path))
    points=[]; lookup={}; faces=[]
    for tri in source:
        ids=[]
        for p in tri:
            if p not in lookup:
                lookup[p]=len(points); points.append(p)
            ids.append(lookup[p])
        faces.append(ids)
    parent=list(range(len(points)))
    def find(i):
        while parent[i]!=i:
            parent[i]=parent[parent[i]]; i=parent[i]
        return i
    for tri in faces:
        for a,b in zip(tri,tri[1:]+tri[:1]):
            if math.dist(points[a],points[b])<0.00003:
                ra,rb=find(a),find(b)
                if ra!=rb: parent[max(ra,rb)]=min(ra,rb)
    max_shift=max(math.dist(p,points[find(i)]) for i,p in enumerate(points))
    assert max_shift<0.0001, ('excessive change',name,max_shift)
    result=[]
    for tri in faces:
        ids=[find(i) for i in tri]
        if len(set(ids))<3: continue
        a,b,c=[points[i] for i in ids]
        normal=cross(tuple(b[j]-a[j] for j in range(3)),tuple(c[j]-a[j] for j in range(3)))
        length=math.sqrt(sum(v*v for v in normal))
        assert length>1e-10, ('unresolved sliver',name,tri)
        result.append((tuple(v/length for v in normal),a,b,c))
    header=b'Experimental M3: numerical edge weld only; not strength tested'.ljust(80,b' ')
    data=bytearray(header+struct.pack('<I',len(result)))
    for n,a,b,c in result:
        data.extend(struct.pack('<12fH',*(n+a+b+c),0))
    path.write_bytes(data)
    return {'file':path.name,'input_triangles':len(source),'output_triangles':len(result),
            'max_vertex_shift_mm':max_shift}

if __name__=='__main__':
    names=sys.argv[1:] or ['test_screw','pcb_screws_m3x4','back_screws_m3x10']
    print(json.dumps([finish(name) for name in names],indent=2))
