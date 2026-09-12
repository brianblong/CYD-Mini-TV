// MINI-TV: lesson 1 / appearance concept, NOT a fitted or print-ready enclosure.
// These are design placeholders, not measurements of a specific CYD board.
// Press F5 to preview. Change cabinet_width, save, and press F5 again.

cabinet_width = 120;   // millimeters, left to right
cabinet_height = 85;   // bottom to top
cabinet_depth = 40;    // back to front
wall = 2.4;
corner_radius = 7;

// Placeholder screen opening. Actual active area and PCB offsets need measuring.
screen_width = 64;
screen_height = 48;
screen_left = 12;
screen_bottom = 25;
knob_radius = 7;
knob_x = cabinet_width - 18;
antenna_length = 24;
antenna_splay = 12;
antenna_diameter = 2.8;
antenna_base_radius = 4;

$fn = 48; // Number of segments used to approximate curves.
epsilon = 0.05;

assert(cabinet_width >= 110, "Keep width at least 110 mm for this concept layout.");
assert(cabinet_height >= 80 && cabinet_depth >= 15);

// A module is a reusable shape, similar to a function in our C++ firmware.
module rounded_box(width, height, depth, radius) {
    hull() {
        for (x = [radius, width - radius])
            for (y = [radius, height - radius])
                translate([x, y, 0])
                    cylinder(h = depth, r = radius);
    }
}

module cabinet() {
    difference() {
        rounded_box(cabinet_width, cabinet_height, cabinet_depth, corner_radius);

        // Subtract the rear cavity, leaving walls and a front panel.
        translate([wall, wall, -epsilon])
            rounded_box(cabinet_width - 2 * wall,
                        cabinet_height - 2 * wall,
                        cabinet_depth - wall + epsilon,
                        corner_radius - wall);

        // Subtract the screen opening through the front panel.
        translate([screen_left, screen_bottom, cabinet_depth - wall - epsilon])
            rounded_box(screen_width, screen_height, wall + 2 * epsilon, 3);
    }
}

module knob(y) {
    color("SaddleBrown")
        translate([knob_x, y, cabinet_depth - epsilon])
            cylinder(h = 5, r = knob_radius);
    color("Wheat")
        translate([knob_x - 0.8, y, cabinet_depth + 4.9])
            cube([1.6, knob_radius - 1, 0.5]);
}

color("BurlyWood") cabinet();
knob(61);
knob(37);

// Short feet overlap the lower cabinet wall; attachment details come later.
for (x = [22, cabinet_width - 34])
    color("SaddleBrown")
        translate([x, -7, 5])
            cube([12, 9, cabinet_depth - 10]);

// Decorative rabbit-ear antennas. +Y is the top edge of the TV.
// These are visual concepts; separate printable parts/sockets will come later.
for (side = [-1,1]) {
    base = [cabinet_width/2 + side*5, cabinet_height - 1, cabinet_depth/2];
    tip = [base[0] + side*antenna_splay, base[1] + antenna_length, base[2]];
    color("SaddleBrown") translate(base) sphere(r = antenna_base_radius);
    color("Silver") hull() {
        translate(base) sphere(d = antenna_diameter);
        translate(tip) sphere(d = antenna_diameter);
    }
}

// The dark screen is only a visual placeholder, not a part to print.
if ($preview)
    color([0.08, 0.12, 0.14])
        translate([screen_left, screen_bottom, cabinet_depth - 1])
            rounded_box(screen_width, screen_height, 0.3, 3);

echo("CONCEPT ONLY: board mounts, port/button access, and rear closure are pending measurements.");
