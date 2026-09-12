// Experimental fit-test nuts, millimeters. Not load-rated hardware.
// Reuse the existing right-handed 0.5 mm-pitch screw profile as a cutter.
use <printed_screws.scad>
part = "test"; // test, eight
$fn = 72;
nut_af = 5.5;
nut_h = 2.0; // Next fit trial after the 1.7 mm revision.
thread_diametral_clearance = 0.30; // Trial allowance for printed screw pairing.
screw_major_d = 2.88;
thread_xy_scale = (screw_major_d+thread_diametral_clearance)/screw_major_d;

module nut() {
    difference() {
        cylinder(d=nut_af/cos(30),h=nut_h,$fn=6);
        // Scale only XY: preserve the screw's 0.5 mm pitch and handedness.
        // The cutter's tapered tip remains beyond the nut.
        translate([0,0,-0.5]) scale([thread_xy_scale,thread_xy_scale,1])
            threaded_shaft(4);
        translate([0,0,-0.01]) cylinder(d1=3.7,d2=2.5,h=0.36);
        translate([0,0,nut_h-0.35]) cylinder(d1=2.5,d2=3.7,h=0.36);
    }
}
if (part=="test") nut();
else if (part=="eight") for (x=[0:3],y=[0:1]) translate([x*9,y*9,0]) nut();
else assert(false,"Select test or eight.");
echo("Experimental nut AF/height:",nut_af,nut_h,
     "thread pitch 0.5 mm; diametral trial clearance:",thread_diametral_clearance);
