// Mini-TV prototype V3: integrated threads, no nuts. Millimeters.
// Construction layout: X right/Y up as viewed from FRONT; depth rearward is +Z.
// That drawing convention is left-handed. PRINT exports mirror X so the actual
// face-down print has its knobs on the right when viewed upright from the front.
// Assembly previews instead mirror Z, equivalent to rotating the physical print.
include <../cyd_dimensions.scad>
use <../prototype_v2/experimental_screws/printed_screws.scad>

part = "assembly"; // housing, back, knobs, antennas, fit_coupon, spacers, assembly, exploded
$fn = 64;
eps = 0.02;

case_w = 132;
case_h = 80;
case_d = 40;
wall = 2.4;
front_t = 2.4;
corner_r = 6;
board_xy = [12,(case_h-pcb_height)/2];
board_front_z = glass_above_pcb_front; // Glass plane = 4 - 4 = 0, flush.
board_back_z = board_front_z + pcb_thickness;
screen_clearance = 0.2; // Per side, beyond the successfully tested opening.
screen_xy = board_xy + fit_test_opening_xy;
screen_wh = fit_test_opening;
board_boss_r = 3.6;

thread_diametral_clearance = 0.30; // Same trial fit as the printed nuts.
pcb_thread_depth = 3.4; // Floor at Z=0.6, screw tip at Z=1: 0.4 mm tip gap.
rear_thread_depth = 8.2; // 7.6 mm screw penetration, 0.6 mm tip gap.
screw_clearance_d = 3.4;
rear_boss_r = 4.8;
rear_centers = [[6,6],[case_w-6,6],[6,case_h-6],[case_w-6,case_h-6]];
back_t = 2.4;
back_lip_h = 1.6;
back_lip_gap = 0.3;
back_lip_w = 1.2;

knob_ys = [29,53];
knob_r = 8;
screen_right = screen_xy[0]+screen_wh[0]+screen_clearance;
knob_x = (screen_right+case_w)/2;
knob_edge_gap = knob_x-knob_r-screen_right;
knob_t = 5;
knob_recess = 0.6;
knob_peg_d = 4;
knob_peg_length = 5;
peg_fit = 0.35; // Diametral clearance, deliberately a slip fit.
knob_flat_x = 1.25;

antenna_base_xs = [case_w/2-12,case_w/2+12];
antenna_base_r = 6;
antenna_base_z = case_d/2;
antenna_angle = 22;
antenna_peg_d = 3.5;
antenna_peg_length = 6;
antenna_socket_depth = 7;
antenna_socket_d = antenna_peg_d + peg_fit;
antenna_flat_z = -1.25; // Flat underside for horizontal printing.

// Measured connector envelope with 0.2 mm clearance per side.
cable_connector_wh = [13,5];
cable_clearance = 0.2;
// Physical prototype feedback: rear pass-through needs 3 mm extra height.
// Preserve the V2 enlarged rear opening and internal plug envelope.
cable_exit_extra_height = 3;
cable_exit_wh = cable_connector_wh + [2*cable_clearance,2*cable_clearance+cable_exit_extra_height];
cable_exit_y = 39;
cable_exit_x = case_w-24;
cable_plug_projection = 30;
usb_center_from_pcb_bottom = 24; // Confirmed for the narrower V2.
usb_center_y = board_xy[1]+usb_center_from_pcb_bottom;
plug_clearance = 0.25;
plug_keepout_lower_y = usb_center_y-cable_connector_wh[0]/2-plug_clearance;

assert(abs(board_front_z-glass_above_pcb_front)<0.001, "Glass must be flush.");
assert(board_back_z == 5 && total_assembly_thickness == 11);
assert(board_front_z-pcb_thread_depth >= 0.6-eps, "Keep closed front under PCB screws.");
assert(pcb_thread_depth > 4-pcb_thickness, "PCB screw must not bottom out.");
assert(rear_thread_depth > 10-back_t, "Rear screw must not bottom out.");
assert(board_xy[0]+pcb_width+cable_plug_projection+1.6 <= case_w-wall+eps,
       "Case must retain room for the 30 mm plugged cable.");
assert(abs(knob_edge_gap-(case_w-knob_x-knob_r))<0.001,
       "Knob edge gaps must match.");
assert(plug_keepout_lower_y-knob_ys[0]-(knob_peg_d+peg_fit)/2 >= 0.8,
       "Keep at least 0.8 mm of plastic above the lower knob socket.");
assert(case_d-back_lip_h > total_assembly_thickness+10);
assert(screen_xy[0]-screen_clearance > board_xy[0]+4+board_boss_r);
assert(cable_exit_x+cable_exit_wh[0]/2 < case_w-wall-back_lip_w);
assert((case_w-60)/5-12 >= 2.4-eps, "Keep material between the unchanged vent slots.");
assert((antenna_base_xs[0]+antenna_base_xs[1])/2 == case_w/2 && antenna_base_z==case_d/2);

module rounded_rect(w,h,r) {
    hull() for (x=[r,w-r]) for (y=[r,h-r]) translate([x,y]) circle(r=r);
}
module case_outline() { rounded_rect(case_w,case_h,corner_r); }
module screen_cut(h=10,z=-eps) {
    translate([screen_xy[0]-screen_clearance,screen_xy[1]-screen_clearance,z])
        cube([screen_wh[0]+2*screen_clearance,screen_wh[1]+2*screen_clearance,h]);
}
module board_positions() {
    for (p=mount_hole_centers) translate([board_xy[0]+p[0],board_xy[1]+p[1],0]) children();
}
// Construction is mirrored on export. Pre-mirror the helical cutter so the
// PHYSICAL housing and coupon have standard right-handed threads.
module threaded_hole(top,depth) {
    scale_xy=(2.88+thread_diametral_clearance)/2.88;
    // Cache each cutter as a solid so F5 does not expand nested CSG across
    // eight threaded holes beyond OpenSCAD's preview tree limit.
    render(convexity=30) union() {
        translate([0,0,top-depth]) mirror([1,0,0])
            scale([scale_xy,scale_xy,1]) threaded_shaft(depth+1);
        translate([0,0,top-0.2]) cylinder(d1=2.5,d2=3.5,h=0.2+eps);
    }
}
module d_peg(d,h,flat) {
    intersection() {
        cylinder(d=d,h=h);
        translate([-d,-d,-eps]) cube([d+flat,2*d,h+2*eps]);
    }
}
module antenna_cross_section() {
    r=antenna_socket_d/2;
    // Teardrop roof prints at 45 degrees; round lower section locates the peg.
    union() {
        circle(r=r);
        polygon([[-r/sqrt(2),r/sqrt(2)],[r/sqrt(2),r/sqrt(2)],[0,r*sqrt(2)]]);
    }
}
function antenna_dir(side) = [side*sin(antenna_angle),cos(antenna_angle),0];
function antenna_entry(i) = [antenna_base_xs[i],case_h,antenna_base_z]
    + antenna_dir(i==0 ? -1 : 1)*(antenna_base_r+0.05);

module housing() {
    difference() {
        union() {
            difference() {
                linear_extrude(case_d) case_outline();
                translate([wall,wall,front_t]) linear_extrude(case_d)
                    rounded_rect(case_w-2*wall,case_h-2*wall,corner_r-wall);
            }
            board_positions() cylinder(r=board_boss_r,h=board_front_z);
            for (p=rear_centers) translate(p) cylinder(r=rear_boss_r,h=case_d);
            for (y=knob_ys) translate([knob_x,y,0]) cylinder(r=5,h=8);
            // True half-spheres centered front-to-back. A tiny overlap joins
            // each dome to the top wall; localized print supports are required.
            for (x=antenna_base_xs) intersection() {
                translate([x,case_h,antenna_base_z]) sphere(r=antenna_base_r);
                translate([x-antenna_base_r-eps,case_h-eps,antenna_base_z-antenna_base_r-eps])
                    cube([2*antenna_base_r+2*eps,antenna_base_r+2*eps,2*antenna_base_r+2*eps]);
            }
            // Two integral feet. Fronts lie on Z=0, like the main housing.
            for (x=[22,case_w-34]) translate([x,-5,0]) cube([12,7,32]);
        }
        screen_cut(case_d+2*eps);
        for (p=mount_hole_centers) {
            x=board_xy[0]+p[0]; y=board_xy[1]+p[1];
            translate([x,y,0]) threaded_hole(board_front_z,pcb_thread_depth);
        }
        for (p=rear_centers) {
            translate(p) threaded_hole(case_d,rear_thread_depth);
        }
        for (y=knob_ys) {
            translate([knob_x,y,-eps]) cylinder(r=knob_r+0.25,h=knob_recess+eps);
            translate([knob_x,y,-eps]) d_peg(knob_peg_d+peg_fit,6.3,knob_flat_x+peg_fit/2);
        }
        for (i=[0,1]) translate(antenna_entry(i))
            rotate([0,0,(i==0 ? 1 : -1)*antenna_angle]) rotate([90,0,0])
                translate([0,0,-eps]) linear_extrude(antenna_socket_depth+eps)
                    antenna_cross_section();
        // The 30 mm plug now shares X with the knobs. Relief trims only the
        // top of the LOWER internal boss; the visible knob, recess and peg stay
        // unchanged. At least 0.825 mm remains above the existing socket.
        cable_envelope(plug_clearance);
    }
}

module cable_envelope(clearance=0) {
    // Right-facing plug: 13 mm width lies along Y. Reserve the full rear
    // component-height band instead of inventing its unmeasured Z center.
    translate([board_xy[0]+pcb_width,usb_center_y-cable_connector_wh[0]/2-clearance,front_t])
        cube([cable_plug_projection+clearance,cable_connector_wh[0]+2*clearance,
              total_assembly_thickness+clearance-front_t]);
}

module slot2d(length,width) {
    hull() for (x=[width/2,length-width/2]) translate([x,width/2]) circle(d=width);
}
module cable_hole(z,h) {
    translate([cable_exit_x-cable_exit_wh[0]/2,cable_exit_y-cable_exit_wh[1]/2,z])
        cube([cable_exit_wh[0],cable_exit_wh[1],h]);
}
// Back cover PRINT orientation: exterior on bed, locating lip points up.
module back_profile() {
    difference() {
        union() {
            linear_extrude(back_t) case_outline();
            translate([wall+back_lip_gap,wall+back_lip_gap,back_t])
                linear_extrude(back_lip_h) difference() {
                    rounded_rect(case_w-2*(wall+back_lip_gap),case_h-2*(wall+back_lip_gap),3.3);
                    translate([back_lip_w,back_lip_w])
                        rounded_rect(case_w-2*(wall+back_lip_gap+back_lip_w),
                                     case_h-2*(wall+back_lip_gap+back_lip_w),2.1);
                }
        }
        for (p=rear_centers) {
            translate([p[0],p[1],-eps]) cylinder(d=screw_clearance_d,h=back_t+back_lip_h+2*eps);
            // Interrupt lip near bosses; solid plate still supports screw heads.
            translate([p[0],p[1],back_t-eps]) cylinder(r=rear_boss_r+0.4,h=back_lip_h+2*eps);
        }
        // Lower and upper rear vent banks; ribs remain between every slot.
        for (y=[12,19,26,52,59,66]) for (i=[0:5])
            let(x=22+i*(case_w-60)/5)
            translate([x,y,-eps]) linear_extrude(back_t+2*eps) slot2d(12,3);
        cable_hole(-eps,back_t+back_lip_h+2*eps);
        // Tie-down slots beside the cable exit for a loose strain-relief cable tie.
        for (x=[case_w-34,case_w-16]) translate([x,45,-eps]) cube([2.5,4,back_t+2*eps]);
    }
}

// Mirror Y in the print layout; rotating the physical cover into place then
// puts its asymmetric cable exit at the intended height in the assembly.
module back_cover() { translate([0,case_h,0]) mirror([0,1,0]) back_profile(); }

module knob() {
    difference() {
        union() {
            cylinder(r=knob_r,h=knob_t);
            translate([0,0,knob_t]) d_peg(knob_peg_d,knob_peg_length,knob_flat_x);
        }
        // Recessed indicator groove; no text. Printable front face remains mostly flat.
        translate([-0.7,0,-eps]) cube([1.4,6.5,0.6+eps]);
        for (a=[0:30:330]) rotate([0,0,a]) translate([knob_r+0.45,0,-eps])
            cylinder(r=0.8,h=knob_t+2*eps);
    }
}
module knobs_print() { for (x=[knob_r,3*knob_r+5]) translate([x,knob_r,0]) knob(); }

// Rod axis is +Y. Flat underside lets both antennas print lying down.
module antenna() {
    intersection() {
        union() {
            rotate([-90,0,0]) cylinder(d=antenna_peg_d,h=antenna_peg_length);
            translate([0,antenna_peg_length,0]) rotate([-90,0,0]) cylinder(d=5.5,h=2);
            translate([0,antenna_peg_length+2,0]) rotate([-90,0,0]) cylinder(d=3.2,h=30);
            translate([0,antenna_peg_length+32,0]) sphere(d=4);
        }
        translate([-5,-eps,antenna_flat_z]) cube([10,50,10]);
    }
}
module antennas_print() { for (x=[3,14]) translate([x,0,-antenna_flat_z]) antenna(); }

module fit_coupon() {
    // Same boss radii, thread depths, entry chamfers and print direction as case.
    // Taller test post is shortened to 12 mm; the top 8.2 mm matches the case.
    difference() {
        union() {
            cube([34,16,0.6]);
            translate([8,8,0]) cylinder(r=board_boss_r,h=board_front_z);
            translate([25,8,0]) cylinder(r=rear_boss_r,h=12);
        }
        translate([8,8,0]) threaded_hole(board_front_z,pcb_thread_depth);
        translate([25,8,0]) threaded_hole(12,rear_thread_depth);
    }
}
module test_spacers() {
    // Loose stand-ins for PCB (1 mm) and cover (2.4 mm), not assembly hardware.
    for (i=[0,1]) translate([6+16*i,6,0]) difference() {
        cylinder(d=i==0 ? 8 : 11,h=i==0 ? pcb_thickness : back_t);
        translate([0,0,-eps]) cylinder(d=screw_clearance_d,h=back_t+2*eps);
    }
}

module visual_board(offset=0) {
    translate([board_xy[0],board_xy[1],offset]) {
        color("SeaGreen") difference() {
            translate([0,0,board_front_z]) cube([pcb_width,pcb_height,pcb_thickness]);
            for (p=mount_hole_centers) translate([p[0],p[1],board_front_z-eps])
                cylinder(d=mount_hole_diameter,h=pcb_thickness+2*eps);
        }
        color("DarkSlateGray") translate([fit_test_opening_xy[0],fit_test_opening_xy[1],0])
            cube([fit_test_opening[0],fit_test_opening[1],glass_above_pcb_front]);
        // No assumed active-pixel rectangle or rear component locations.
    }
}
module assembly(explode=0) {
    color("BurlyWood") housing();
    visual_board(explode*0.4);
    color("SaddleBrown") translate([0,case_h,case_d+back_t+explode]) rotate([180,0,0]) back_cover();
    color("DimGray") for (y=knob_ys) translate([knob_x,y,knob_recess-knob_t-explode*0.25]) knob();
    color("Silver") for (i=[0,1]) {
        side=i==0 ? -1 : 1;
        translate(antenna_entry(i)+antenna_dir(side)*(-antenna_peg_length+explode*0.2))
            rotate([0,0,-side*antenna_angle]) antenna();
    }
}

module collision_check() {
    // Move seating surfaces apart by 0.01 mm to avoid CGAL coplanar-contact
    // artifacts. Positive volume after that tolerance signals an overlap.
    contact_tolerance=0.01;
    intersection() {
        housing();
        union() {
            visual_board(contact_tolerance);
            translate([0,case_h,case_d+back_t+contact_tolerance]) rotate([180,0,0]) back_cover();
            for (y=knob_ys) translate([knob_x,y,knob_recess-knob_t-contact_tolerance]) knob();
            for (i=[0,1]) translate(antenna_entry(i)-antenna_dir(i==0 ? -1 : 1)*antenna_peg_length)
                rotate([0,0,(i==0 ? 1 : -1)*antenna_angle]) antenna();
            translate([0,0,contact_tolerance]) cable_envelope();
        }
    }
    intersection() {
        cable_envelope();
        for (y=knob_ys) translate([knob_x,y,knob_recess-knob_t]) knob();
    }
}

if (part=="housing") translate([case_w,0,0]) mirror([1,0,0]) housing();
else if (part=="back") translate([case_w,0,0]) mirror([1,0,0]) back_cover();
else if (part=="knobs") translate([4*knob_r+5,0,0]) mirror([1,0,0]) knobs_print();
else if (part=="antennas") antennas_print(); // Symmetric about each rod's X axis.
else if (part=="fit_coupon") translate([34,0,0]) mirror([1,0,0]) fit_coupon();
else if (part=="spacers") test_spacers();
else if (part=="collision_check") collision_check();
else if (part=="exploded") mirror([0,0,1]) assembly(36);
else if (part=="assembly") mirror([0,0,1]) assembly();
else assert(false,"Unknown part selection.");

echo("V3 body:",[case_w,case_h,case_d],"front glass plane:",board_front_z-glass_above_pcb_front);
echo("Threaded hole depths PCB/rear:",pcb_thread_depth,rear_thread_depth,
     "Screw penetration PCB/rear:",4-pcb_thickness,10-back_t);
echo("Equal knob edge gaps:",knob_edge_gap,"knob center X:",knob_x);
echo("PCB front/back and maximum assembly depth:",board_front_z,board_back_z,total_assembly_thickness);
echo("Screen opening:",screen_wh+[2*screen_clearance,2*screen_clearance]);
echo("Cable projection:",cable_plug_projection,"rear opening:",cable_exit_wh);
echo("USB center from PCB bottom:",usb_center_from_pcb_bottom,
     "remaining lower knob socket wall:",plug_keepout_lower_y-knob_ys[0]-(knob_peg_d+peg_fit)/2);
