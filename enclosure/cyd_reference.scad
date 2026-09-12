// Open this file and press F5. No assumed USB/frame/button geometry is drawn.
include <cyd_dimensions.scad>

mode = "reference"; // "reference" = visual reference; "footprint" = exact 2D PCB
require_verified = false; // Keep false for reference work; true enforces known fit data.
$fn = 64;

// Rendering aids ONLY; neither is a measured physical thickness.
reference_sheet_thickness = 0.4;
reference_active_sheet_thickness = 0.2;

assert(pcb_width > 0 && pcb_height > 0 && mount_hole_diameter > 0);
if (!is_undef(display_frame_xy) && !is_undef(display_frame_outline))
assert(display_frame_xy[0] >= 0 && display_frame_xy[1] >= 0 &&
       display_frame_xy[0] + display_frame_outline[0] <= pcb_width &&
       display_frame_xy[1] + display_frame_outline[1] <= pcb_height,
       "Display frame outline extends beyond the measured PCB.");
assert(len(mount_hole_centers) == 4, "Expected four mounting holes.");
assert(mount_hole_centers[1][0] - mount_hole_centers[0][0] == mount_center_spacing[0] &&
       mount_hole_centers[3][0] - mount_hole_centers[2][0] == mount_center_spacing[0] &&
       mount_hole_centers[2][1] - mount_hole_centers[0][1] == mount_center_spacing[1] &&
       mount_hole_centers[3][1] - mount_hole_centers[1][1] == mount_center_spacing[1],
       "Hole coordinates must agree with the recorded center spacing.");
for (p = mount_hole_centers)
    assert(p[0] >= mount_hole_diameter/2 &&
           p[0] <= pcb_width - mount_hole_diameter/2 &&
           p[1] >= mount_hole_diameter/2 &&
           p[1] <= pcb_height - mount_hole_diameter/2,
           "Mounting hole crosses a PCB edge.");

if (require_verified) {
    assert(mounting_pattern_verified, "Verify mounting holes on actual USB-C revision first.");
    assert(!is_undef(pcb_thickness) && !is_undef(display_frame_size) &&
           !is_undef(display_frame_position) && !is_undef(active_display_position) &&
           !is_undef(total_assembly_thickness) && !is_undef(assembly_z_min) &&
           !is_undef(usb_c_cutout) && !is_undef(micro_usb_cutout) &&
           !is_undef(microsd_access) && !is_undef(boot_button_access) &&
           !is_undef(reset_button_access), "Fit-critical parameters remain unverified.");
}

module cyd_pcb_footprint() {
    difference() {
        square([pcb_width, pcb_height]);
        for (p = mount_hole_centers)
            translate(p) circle(d = mount_hole_diameter);
    }
}

module access_reference(box) {
    if (!is_undef(box))
        color([1,0.4,0,0.45])
            translate([box[0],box[1],box[2]]) cube([box[3],box[4],box[5]]);
}

module cyd_reference() {
    color("Goldenrod")
        linear_extrude(height = is_undef(pcb_thickness) ? reference_sheet_thickness : pcb_thickness)
            cyd_pcb_footprint();

    if (!is_undef(display_frame_size) && !is_undef(display_frame_position))
        color([0.35,0.35,0.35,0.6])
            translate(display_frame_position) cube(display_frame_size);
    else if (!is_undef(display_frame_xy) && !is_undef(display_frame_outline))
        // Measured XY outline only. Ring thickness/Z placement are visualization aids.
        color("DimGray")
            translate([display_frame_xy[0],display_frame_xy[1],
                       is_undef(pcb_thickness) ? reference_sheet_thickness : pcb_thickness])
                linear_extrude(height = reference_active_sheet_thickness)
                    difference() {
                        square(display_frame_outline);
                        translate([0.5,0.5])
                            square([display_frame_outline[0]-1,display_frame_outline[1]-1]);
                    }

    // With no measured position, show the active area BESIDE the PCB, not centered on it.
    color("SteelBlue")
        translate(is_undef(active_display_position) ? [pcb_width + 10,0,0] : active_display_position)
            cube([active_display_size[0],active_display_size[1],reference_active_sheet_thickness]);

    if (!is_undef(total_assembly_thickness) && !is_undef(assembly_z_min))
        color([0.2,0.8,0.7,0.15])
            translate([0,0,assembly_z_min])
                cube([pcb_width,pcb_height,total_assembly_thickness]);

    for (box = [usb_c_cutout,micro_usb_cutout,microsd_access,boot_button_access,reset_button_access])
        access_reference(box);
}

if (mode == "footprint") cyd_pcb_footprint();
else {
    assert(mode == "reference", "Choose reference or footprint mode.");
    cyd_reference();
}
echo("Provisional hole centers:", mount_hole_centers, "nominal diameter:", mount_hole_diameter);
echo("Measured PCB:", [pcb_width,pcb_height], "frame XY:", display_frame_outline, display_frame_xy);
echo("Hole edge offsets remain provisional pending physical alignment test.");
echo("USB-C revision mounting pattern verified:", mounting_pattern_verified);
echo("Actual board center spacing:", mount_center_spacing,
     "verified:", mount_center_spacing_verified);
if (is_undef(pcb_thickness)) echo("PCB is a 0.4 mm VISUAL sheet, not a measured thickness.");
if (is_undef(active_display_position)) echo("Blue active area is shown separately because its position is UNKNOWN.");
