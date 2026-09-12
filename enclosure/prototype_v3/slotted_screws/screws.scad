// Revised drive heads only. Existing successful V2/V3 threads are imported.
// Millimeters. Print head down, shaft up. Do not mirror or scale.
use <../../prototype_v2/experimental_screws/printed_screws.scad>
part="test"; // test, pcb, back, head_preview
$fn=72;
head_d=5.5; // Same maximum diameter as original; now six exterior flats.
head_h=2.4;
slot_length=4.2;
slot_width=1.0;
slot_depth=1.2;
eps=0.02;
root_r=2.88/2-17*sqrt(3)*0.5/48;

module drive_head() {
    difference() {
        cylinder(d=head_d,h=head_h,$fn=6);
        translate([-slot_length/2,-slot_width/2,-eps])
            cube([slot_length,slot_width,slot_depth+eps]);
    }
}
module screw(length) {
    assert(length==4 || length==10);
    union() {
        drive_head();
        translate([0,0,head_h-eps]) cylinder(r=root_r,h=2*eps);
        translate([0,0,head_h]) threaded_shaft(length);
    }
}
module four(length) {
    for(x=[2.75,11.75],y=[2.75,11.75]) translate([x,y,0]) screw(length);
}
if(part=="test") translate([2.75,2.75,0]) screw(10);
else if(part=="pcb") four(4);
else if(part=="back") four(10);
else if(part=="head_preview") rotate([180,0,0]) drive_head();
else assert(false,"Select test, pcb, back or head_preview");
echo("Head: 5.5 mm across corners, 2.4 mm tall; slot:",slot_length,slot_width,slot_depth);
