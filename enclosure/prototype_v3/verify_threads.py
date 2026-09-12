"""Inspect exported hole surfaces: pitch, right-hand direction and blind depth."""
from pathlib import Path
import math
import numpy as np
from verify_meshes import triangles

ROOT = Path(__file__).resolve().parent

def check_file(filename, holes):
    tris=np.asarray(list(triangles(ROOT/filename)))
    a=tris[:,0]; e1=tris[:,1]-a; e2=tris[:,2]-a
    def ray(origin,direction):
        d=np.array(direction); origin=np.array(origin)
        h=np.cross(d,e2); det=np.einsum('ij,ij->i',e1,h)
        active=np.abs(det)>1e-10
        f=np.zeros_like(det); f[active]=1/det[active]
        s=origin-a; u=f*np.einsum('ij,ij->i',s,h)
        q=np.cross(s,e1); v=f*(q@d); t=f*np.einsum('ij,ij->i',e2,q)
        valid=active & (u>=-1e-7) & (v>=-1e-7) & (u+v<=1+1e-7) & (t>1e-6)
        assert valid.any(), (filename,origin,direction)
        return float(t[valid].min())
    for x,y,top,depth in holes:
        floor=top-depth
        radii=[ray([x,y,floor+1],[1,0,0]),
               ray([x,y,floor+1.5],[1,0,0]),
               ray([x,y,floor+1.125],[0,1,0])]
        assert all(abs(r-1.59)<0.015 for r in radii), (filename,x,y,radii)
        root=ray([x,y,floor+0.875],[0,1,0])
        expected=(1.44-17*math.sqrt(3)*0.5/48)*(3.18/2.88)
        assert abs(root-expected)<0.015, (filename,x,y,root)
        actual_depth=ray([x,y,top+0.1],[0,0,-1])-0.1
        assert abs(actual_depth-depth)<0.001, (filename,x,y,actual_depth)
    print(f'{filename}: {len(holes)} blind holes pass 0.5 mm pitch, right-handed helix and depth checks.')

if __name__ == '__main__':
    pcb=[(132-(12+x),14.75+y,4,3.4) for x,y in [(4,4),(82.5,4),(4,46),(82.5,46)]]
    rear=[(132-x,y,40,8.2) for x,y in [(6,6),(126,6),(6,74),(126,74)]]
    check_file('housing.stl',pcb+rear)
    check_file('fit_coupon.stl',[(26,8,4,3.4),(9,8,12,8.2)])
