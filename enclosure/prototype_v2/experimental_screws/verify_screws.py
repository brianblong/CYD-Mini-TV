"""Reuse the case mesh checks for the experimental screw exports."""
from pathlib import Path
import json
import sys
import math
import numpy as np

ROOT = Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT.parent))
import verify_meshes as mesh
mesh.ROOT=ROOT
expected={
    "test_screw": (1,(5.5,5.5,12.4)),
    "pcb_screws_m3x4": (4,(14.5,14.5,6.4)),
    "back_screws_m3x10": (4,(14.5,14.5,12.4)),
}
print(json.dumps([mesh.check(name,spec) for name,spec in expected.items()],indent=2))

# Check actual exported thread surface, not just the source formulas. Ray-cast
# away from the axis at selected phases to verify pitch, diameter and handedness.
tris=np.asarray(list(mesh.triangles(ROOT/'test_screw.stl')))
a=tris[:,0]; e1=tris[:,1]-a; e2=tris[:,2]-a
def radial_surface(theta,z):
    d=np.array([math.cos(theta),math.sin(theta),0.0])
    origin=np.array([2.75,2.75,z])
    h=np.cross(d,e2)
    det=np.einsum('ij,ij->i',e1,h)
    active=np.abs(det)>1e-10
    f=np.zeros_like(det); f[active]=1/det[active]
    s=origin-a
    u=f*np.einsum('ij,ij->i',s,h)
    q=np.cross(s,e1)
    v=f*(q@d)
    t=f*np.einsum('ij,ij->i',e2,q)
    valid=active & (u>=-1e-7) & (v>=-1e-7) & (u+v<=1+1e-7) & (t>0)
    assert valid.any(), (theta,z)
    return float(t[valid].max())

crest0=radial_surface(0,4.4)
crest_next=radial_surface(0,4.9)
crest_quarter=radial_surface(math.pi/2,4.525)
root_quarter=radial_surface(math.pi/2,4.275)
assert all(abs(r-1.44)<0.01 for r in [crest0,crest_next,crest_quarter])
assert abs(root_quarter-(1.44-17*math.sqrt(3)*0.5/48))<0.01
print('Exported helix checks passed: 0.5 mm pitch; right-handed; 2.88 mm major diameter.')
