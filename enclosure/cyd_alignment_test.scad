// Flat outline/hole alignment gauge, millimeters. Not a board mounting carrier.
include <cyd_dimensions.scad>
$fn = 64;
test_thickness = 1.6;
side_rail_width = 8;
outside_bridge_width = 4;
test_hole_diameter = 3.4; // 0.2 mm over nominal; printed clearance is approximate.
assert(pcb_width > 2*side_rail_width);
assert(test_thickness > 0 && test_hole_diameter > 0);
linear_extrude(height = test_thickness)
    difference() {
        // Top/bottom bridges sit OUTSIDE the PCB so they do not cover the display.
        translate([0,-outside_bridge_width])
            square([pcb_width,pcb_height+2*outside_bridge_width]);
        translate([side_rail_width,0])
            square([pcb_width-2*side_rail_width,pcb_height]);
        for (p = mount_hole_centers)
            translate(p) circle(d = test_hole_diameter);
    }
echo("Test outline:", [pcb_width,pcb_height], "hole centers:", mount_hole_centers);
echo("Provisional left/bottom offsets 4 mm. Derived right 3.5, top 4.5 mm.");
echo("Opening:", [pcb_width-2*side_rail_width,pcb_height],
     "with top/bottom bridges outside PCB outline.");
