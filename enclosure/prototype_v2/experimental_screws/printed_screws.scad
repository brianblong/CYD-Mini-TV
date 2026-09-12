// EXPERIMENTAL printed M3 screws for mini-TV V1/V2. Millimeters.
// Not strength-rated or physically thread-gauged. Use metal M3 nuts.
// Head/drive face is on the print bed. Thread rises in +Z, right-handed.
part = "test"; // test, pcb, back, preview
$fn = 72;
eps = 0.02;

pitch = 0.5;
reference_major_d = 2.98; // M3 6g maximum major diameter, before print compensation.
diameter_compensation = 0.10; // Diametral reduction for trial fit, NOT a certified tolerance.
major_d = reference_major_d-diameter_compensation;
// Truncated 60-degree external profile; simplified flat root, no root fillet.
thread_depth = 17*sqrt(3)*pitch/48;
root_r = major_d/2-thread_depth;
crest_width = pitch/8;
helix_overlap = 0.02;
head_d = 5.5;
head_h = 2.4;
drive_af = 2.1; // Trial clearance for a 2 mm hex key. Use very little torque.
drive_depth = 1.2;
tip_chamfer = 0.35;
samples_per_turn = 72;
layout_spacing = 9;

assert(pitch == 0.5 && root_r>1 && major_d<3);
assert(diameter_compensation>=0 && diameter_compensation<=0.2);
assert(head_h>drive_depth+1);

module helical_ridge(length) {
    turns=ceil(length/pitch)+2;
    steps=turns*samples_per_turn;
    inner_r=root_r-helix_overlap;
    base_width=crest_width+2*(major_d/2-inner_r)/tan(60);
    assert(base_width<pitch, "Adjacent ridge turns must remain separate before core union.");
    profile=[[inner_r,-base_width/2],[major_d/2,-crest_width/2],
             [major_d/2,crest_width/2],[inner_r,base_width/2]];
    points=[for (i=[0:steps]) for (p=profile)
        let(a=360*i/samples_per_turn,z=-pitch+pitch*i/samples_per_turn)
            [p[0]*cos(a),p[0]*sin(a),z+p[1]]];
    // Build mathematical outward triangles, then reverse for OpenSCAD's
    // clockwise-from-outside polyhedron convention (opposite STL convention).
    sides=[for (i=[0:steps-1]) for (j=[0:3])
        each [[4*i+j,4*(i+1)+j,4*(i+1)+(j+1)%4],
              [4*i+j,4*(i+1)+(j+1)%4,4*i+(j+1)%4]]];
    outward=concat([[0,1,2,3]],sides,[[4*steps+3,4*steps+2,4*steps+1,4*steps]]);
    polyhedron(points=points,faces=[for (f=outward) [for (j=[len(f)-1:-1:0]) f[j]]],convexity=30);
}

module threaded_shaft(length) {
    intersection() {
        union() {
            cylinder(r=root_r,h=length);
            helical_ridge(length);
        }
        // Clips both end faces and provides a short tapered thread lead-in.
        union() {
            cylinder(d=major_d+eps,h=length-tip_chamfer);
            translate([0,0,length-tip_chamfer])
                cylinder(d1=major_d+eps,d2=2*root_r-0.1,h=tip_chamfer);
        }
    }
}

module screw(length) {
    assert(length==4 || length==10, "Do not substitute longer screws at the PCB.");
    difference() {
        union() {
            cylinder(d=head_d,h=head_h);
            // A very small overlap connects the shaft to the head without
            // changing the under-head length or the end of the screw.
            translate([0,0,head_h-eps]) cylinder(r=root_r,h=2*eps);
            translate([0,0,head_h]) threaded_shaft(length);
        }
        translate([0,0,-eps]) cylinder(d=drive_af/cos(30),h=drive_depth+eps,$fn=6);
    }
}
module four(length) {
    for (x=[head_d/2,head_d/2+layout_spacing])
        for (y=[head_d/2,head_d/2+layout_spacing]) translate([x,y,0]) screw(length);
}

if (part=="test") translate([head_d/2,head_d/2,0]) screw(10);
else if (part=="pcb") four(4);
else if (part=="back") four(10);
else if (part=="preview") {
    translate([0,0,0]) screw(4);
    translate([9,0,0]) screw(10);
}
else assert(false,"Select test, pcb, back or preview.");

echo("EXPERIMENTAL right-hand M3 x 0.5; major diameter:",major_d,
     "root diameter:",2*root_r,"head height:",head_h);
echo("Under-head lengths: PCB 4 mm; back 10 mm. Metal nuts still required.");
