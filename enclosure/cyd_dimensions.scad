// ESP32-2432S028R reference based on physical board measurements, millimeters.
// Coordinate origin: lower-left PCB corner viewed from the display side.
// X follows the 86 mm edge, Y follows the 50.5 mm edge; +Z faces the display.
// Nominal reference values; see verification flags for measurements on this unit.
// Measured edge-to-edge on a sample board; overrides manufacturer 86 x 50.
pcb_width = 86.0;
pcb_height = 50.5;
pcb_outline_verified = true;
mount_hole_diameter = 3.2;
// Four-hole layout accepted after a successful physical alignment print.
// Right margin 3.5 and top margin 4.5, not all margins 4.
mount_origin = [4,4];
mount_hole_centers = [for (y = [0,42]) for (x = [0,78.5])
                     [mount_origin[0]+x,mount_origin[1]+y]];
active_display_size = [57.6,43.2]; // Illuminated area ONLY, not frame size.
// Earlier 70 x 51 frame / flush edges conflict with latest PCB measurements.
display_frame_outline = undef;
display_frame_xy = undef;
display_frame_outline_verified = false;

// Corrected hole center spacing from a physical sample board.
mount_center_spacing = [78.5,42.0];
mount_center_spacing_verified = true;
// Spacing confirmation alone does not measure diameter or offsets from PCB edges.
mount_edge_offsets_verified = true; // Physical gauge fit, not caliper precision.
mount_hole_diameter_verified = false;
mounting_pattern_verified = mount_center_spacing_verified &&
                            mount_edge_offsets_verified && mount_hole_diameter_verified;

// Leave these undefined until verified on the actual dual-USB board.
pcb_thickness = 1.0;
glass_above_pcb_front = 4.0;
fit_test_opening = [70.0,50.5]; // Accepted opening; not a glass precision measurement.
fit_test_opening_xy = [8.0,0.0];
display_frame_size = undef;       // [width,height,depth]
display_frame_position = undef;   // [x,y,z] lower-left/back of outer frame
active_display_position = undef;  // [x,y,z] lower-left of illuminated area
total_assembly_thickness = 11.0;
assembly_z_min = -6.0; // PCB + rear components = 7 mm; PCB itself = 1 mm.

// Each opening is [x,y,z,width,height,depth] in board coordinates.
// Include plug/finger/card travel clearance when sizing enclosure cutouts.
usb_c_cutout = undef;
micro_usb_cutout = undef;
microsd_access = undef;
boot_button_access = undef;
reset_button_access = undef;
