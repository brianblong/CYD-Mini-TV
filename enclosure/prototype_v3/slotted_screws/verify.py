"""Finish meshes; check topology, head slot and unchanged shaft surfaces."""
from pathlib import Path
import importlib.util
import sys
import json
import math
import numpy as np

ROOT=Path(__file__).resolve().parent
OLD=ROOT.parent.parent/'prototype_v2/experimental_screws'
sys.path.insert(0,str(ROOT.parent))
import verify_meshes as mesh
spec=importlib.util.spec_from_file_location('finish',OLD/'finish_stls.py')
finish=importlib.util.module_from_spec(spec); spec.loader.exec_module(finish)
finish.ROOT=ROOT
mesh.ROOT=ROOT
af=5.5*math.cos(math.pi/6)
expected={'test_screw':(1,(5.5,af,12.4)),
          'pcb_screws_m3x4':(4,(14.5,9+af,6.4)),
          'back_screws_m3x10':(4,(14.5,9+af,12.4))}

def ray(tris,origin,direction):
    a=tris[:,0]; e1=tris[:,1]-a; e2=tris[:,2]-a
    d=np.array(direction); s=np.array(origin)-a
    h=np.cross(d,e2); det=np.einsum('ij,ij->i',e1,h)
    active=np.abs(det)>1e-10
    f=np.zeros_like(det); f[active]=1/det[active]
    u=f*np.einsum('ij,ij->i',s,h); q=np.cross(s,e1)
    v=f*(q@d); t=f*np.einsum('ij,ij->i',e2,q)
    valid=active & (u>=-1e-7) & (v>=-1e-7) & (u+v<=1+1e-7) & (t>1e-6)
    assert valid.any(),(origin,direction)
    return float(t[valid].min())

if __name__=='__main__':
    print(json.dumps([finish.finish(n) for n in expected],indent=2))
    print(json.dumps([mesh.check(n,e) for n,e in expected.items()],indent=2))
    max_error=0
    for name in expected:
        new=np.asarray(list(mesh.triangles(ROOT/(name+'.stl'))))
        old=np.asarray(list(mesh.triangles(OLD/(name+'.stl'))))
        length=4 if name.startswith('pcb') else 10
        centers=[(2.75,2.75)] if name=='test_screw' else [(x,y) for x in [2.75,11.75] for y in [2.75,11.75]]
        for x,y in centers:
            def local(tris):
                return tris[np.all((abs(tris[:,:,0]-x)<3)&(abs(tris[:,:,1]-y)<3),axis=1)]
            n=local(new); o=local(old)
            for z in [2.65,3.17,3.53,3.91,4.19,2.4+length-0.2]:
                for theta in [0,0.4,1.3,2.7]:
                    d=[math.cos(theta),math.sin(theta),0]
                    error=abs(ray(n,[x,y,z],d)-ray(o,[x,y,z],d))
                    max_error=max(max_error,error)
                    assert error<0.001,(name,x,y,z,theta,error)
            # Drive opening corners inside the slot hit its 1.2 mm floor.
            for dx,dy in [(0,0),(2.05,0.45),(-2.05,-0.45)]:
                assert abs(ray(n,[x+dx,y+dy,-0.1],[0,0,1])-1.3)<0.001
            # Immediately outside the slot, the head starts at the bed plane.
            for dx,dy in [(2.15,0),(0,0.55)]:
                assert abs(ray(n,[x+dx,y+dy,-0.1],[0,0,1])-0.1)<0.001
    print(f'All nine screws: slot bounds/depth pass; sampled shafts match original within {max_error:.8f} mm.')
